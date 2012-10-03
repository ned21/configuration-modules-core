# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::spma;
#
# a few standard statements, mandatory for all components
#
use strict;
use warnings;
use NCM::Component;
our $EC=LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
use EDG::WP4::CCM::Element qw(unescape);

use CAF::Process;
use CAF::FileWriter;
use LC::Exception qw(SUCCESS);
use Set::Scalar;
use File::Path qw(mkpath);
use Readonly;

Readonly my $REPOS_DIR => "/etc/yum.repos.d";
Readonly my $REPOS_TEMPLATE => "spma/repository.tt";
Readonly my $REPOS_TREE => "/software/repositories";
Readonly my $PKGS_TREE => "/software/packages";
Readonly my $CMP_TREE => "/software/components/${project.artifactId}";
Readonly my $YUM_CMD => [qw(yum -y shell)];
Readonly my $RPM_QUERY => [qw(rpm -qa --qf %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n)];
Readonly my $REMOVE => "remove";
Readonly my $INSTALL => "install";
Readonly my $YUM_PACKAGE_LIST => "/etc/yum/pluginconf.d/versionlock.list";

our $NoActionSupported = 1;

# If user packages are not allowed, removes any repositories present
# in the system that are not listed in $allowed_repos.
sub cleanup_old_repos
{
    my ($self, $repo_dir, $allowed_repos, $allow_user_pkgs) = @_;

    return 1 if $allow_user_pkgs;

    my $dir;
    if (!opendir($dir, $repo_dir)) {
	$self->error("Unable to read repositories in $repo_dir");
	return 0;
    }

    my $current = Set::Scalar->new(map(m{(.*)\.repo$}, readdir($dir)));

    closedir($dir);
    my $allowed = Set::Scalar->new(map($_->{name}, @$allowed_repos));
    my $rm = $current-$allowed;
    foreach my $i (@$rm) {
	# We use $f here to make Devel::Cover happy
	my $f = "$repo_dir/$i.repo";
	$self->verbose("Unlinking outdated repository $f");
	if (!unlink($f)) {
	    $self->error("Unable to remove outdated repository $i: $!");
	    return 0;
	}
    }
    return 1;
}

# Creates the repository dir if needed.
sub initialize_repos_dir
{
    my ($self, $repo_dir) = @_;
    if (! -d $repo_dir) {
	$self->verbose("$repo_dir didn't exist. Creating it");
	if (!eval{mkpath($repo_dir)} || $@) {
	    $self->error("Unable to create repository dir $repo_dir: $@");
	    return 0;
	}
    }
    return 1;
}

# Generates the repository files in $repos_dir based on the contents
# of the $repos subtree. It uses Template::Toolkit $template to render
# the file. Optionally, proxy information will be used. In that case,
# it will use the $proxy host, wich is of $type "reverse" or
# "forward", and runs on the given $port.
sub generate_repos
{
    my ($self, $repos_dir, $repos, $template, $proxy, $type, $port) = @_;

    $proxy .= ":$port" if defined($port);


    foreach my $repo (@$repos) {
	my $fh = CAF::FileWriter->new("$repos_dir/$repo->{name}.repo",
				      log => $self);
	print $fh "# File generated by ", __PACKAGE__, ". Do not edit\n";
	# Only forward proxies are handled here. Forward proxies
	# should be specified in /etc/yum.conf, in the proxyhost=
	# field.
	if ($proxy && ($type eq 'forward')) {
	    $repo->{protocols}->[0]->{url} =~ s{^(.*?)://[^/]+(/?)}{$1://$proxy$2};
	}

	my $rs = $self->template()->process($template, $repo, $fh);
	if (!$rs) {
	    $self->error ("Unable to generate repository $repo->{name}: ",
			  $self->template()->error());
	    $fh->cancel();
	    return 0;
	}
	$fh->close();
	$fh = CAF::FileWriter->new("$repos_dir/$repo->{name}.pkgs",
				   log => $self);
	print $fh "# Additional configuration for $repo->{name}\n";
	$fh->close();
    }

    return 1;
}

# Returns a yum shell line for $op-erating on the $target
# packages. $op is typically "install" or "remove".
sub schedule
{
    my ($self, $op, $target) = @_;

    return @$target ? sprintf("%s %s\n", $op, join(" ", @$target)) : "";
}

# Returns a set of all installed packages
sub installed_pkgs
{
    my $self = shift;

    my $cmd = CAF::Process->new($RPM_QUERY, keeps_state => 1,
				log => $self);

    my $out = $cmd->output();
    if ($?) {
	return undef;
    }
    # We don't consider gpg-pubkeys, which won't come from any
    # downloaded RPM, anyways.
    my @pkgs = grep($_ !~ m{^gpg-pubkey.*\(none\)$}, split(/\n/, $out));

    return Set::Scalar->new(@pkgs);
}

# Returns a set with the desired packages.
sub wanted_pkgs
{
    my ($self, $pkgs) = @_;

    my @pkl;

    while (my ($pkg, $st) = each(%$pkgs)) {
	while (my ($ver, $arch) = each(%$st)) {
	    foreach my $i (keys(%{$arch->{arch}})) {
		push(@pkl, sprintf("%s-%s.%s", unescape($pkg), unescape($ver), $i));
	    }
	}
    }
    return Set::Scalar->new(@pkl);
}

# Returns the yum shell command to apply the transaction. If run, the
# transaction will be applied. Otherwise it will just be solved and
# printed.
sub solve_transaction {
    my ($self, $run) = @_;

    my $rs = "transaction solve\n";
    if ($run && !$NoAction) {
	$rs .= "transaction run\n";
    }
    return $rs;
}

# Actually calls yum to execute transaction $tx
sub apply_transaction
{

    my ($self, $tx) = @_;

    $self->debug(5, "Running transaction: $tx");

    my $cmd = CAF::Process->new($YUM_CMD, log => $self, stdin => $tx,
    				stdout => \my $rs, stderr => 'stdout',
				keeps_state => 1);

    $cmd->execute();

    if ($?) {
    	$self->error("Failed to execute transaction: $rs");
    } else {
    	$self->info("Yum output: $rs");
    }
    return !$?;
}

# Lock the versions of all packages, for the versionlock Yum plugin.
sub versionlock
{
    my ($self, $wanted) = @_;

    my $fh = CAF::FileWriter->new($YUM_PACKAGE_LIST, log => $self);
    print $fh join("\n", @$wanted, "");
    $fh->close();
}


# Updates the packages on the system.
sub update_pkgs
{
    my ($self, $pkgs, $run, $allow_user_pkgs) = @_;

    my $installed = $self->installed_pkgs();
    defined($installed) or return 0;
    my $wanted = $self->wanted_pkgs($pkgs);
    defined($wanted) or return 0;

    my ($tx, $rs);

    if (!$allow_user_pkgs) {
	$tx = $self->schedule($REMOVE, $installed-$wanted);
    }

    # Schedulling the installation of all wanted packages over and
    # over again will work. But it will be unnecessarily slow. We can
    # greatly reduce the size of the transaction if we just tell Yum
    # to install what is missing.
    $tx .= $self->schedule($INSTALL, $wanted-$installed);

    $tx .= $self->solve_transaction($run);

    $self->apply_transaction($tx) or return 0;
    $self->versionlock($wanted);
    return 1;
}

sub Configure
{
    my ($self, $config) = @_;

    my $repos = $config->getElement($REPOS_TREE)->getTree();
    my $t = $config->getElement($CMP_TREE)->getTree();
    # Convert these crappily-defined fields into real Perl booleans.
    $t->{run} = $t->{run} eq 'yes';
    $t->{userpkgs} = defined($t->{userpkgs}) && $t->{userpkgs} eq 'yes';
    my $pkgs = $config->getElement($PKGS_TREE)->getTree();
    $self->initialize_repos_dir($REPOS_DIR) or return 0;
    $self->cleanup_old_repos($REPOS_DIR, $repos, $t->{userpkgs}) or return 0;
    $self->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE, $t->{proxyhost},
			  $t->{proxytype}, $t->{proxyport}) or return 0;
    $self->update_pkgs($pkgs, $t->{run}, $t->{userpkgs})
      or return 0;
    return 1;
}

1; # required for Perl modules
