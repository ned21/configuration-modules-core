# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# linuxha component
#
# configure linux-ha settings and resources as per CDB
# REWRITES /etc/ha.d/{ha.cf,authkeys,haresources}
#
# Andras Horvath <Andras.Horvath@cern.ch>
# 25/10/2005
#
# TODO:	
#	use config.mk variables for pathnames
#	should we use CDB instead of gethostbyname()?
#
#######################################################################

package NCM::Component::linuxha;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use LC::Process;
use LC::File;
use Socket; # for IP gethostbyname() of cluster members - should we use CDB instead? XXX

#
# damn exceptions. Damn OO perl, for that matter. Why OO for 200 lines of code?
#
$EC->error_handler(\&my_handler);
sub my_handler {
	my($ec, $e) = @_;
	$e->has_been_reported(1);
}

##########################################################################
sub Configure {
##########################################################################
	my ($self,$config)=@_;

	my $valPath = '/software/components/linuxha';

	unless ($config->elementExists($valPath)) {
		$self->error("cannot get $valPath");
		return;
	}

	#my $cnt = 0;
	my $re; # root element (of subtrees in our config)
	my $ce; # current processed config element
	my $val; # value (temporary) retrieved for a given config element
	my @node_list; # list of nodes in this cluster (by hostname)

	my $reload=0; # shall we reload the config file?

#### ha.cf ####

	my $old_hacf=LC::File::file_contents("/etc/ha.d/ha.cf");
	if (not $old_hacf) { $old_hacf=" "; }

	my $hacf="###\n### NCM-autogenerated ###\n###i Do not edit but run ncm_wrappers.sh --co linuxha\n###\n"; # assembled haresources file contents

	# get the mandatory constants. Most of these need to be defined upfront in the
	# config file (eg. udpport before communication details)
	#
	foreach $ce ( qw(
			use_logd
			keepalive
			deadtime
			warntime
			initdead
			auto_failback
			udpport
	) ) {
		unless ($config->elementExists($valPath."/".$ce)) {
			$self->error("mandatory config element $ce not found!");
			return;
		}
		$val=$config->getValue($valPath."/".$ce);
		$hacf.="$ce $val\n";
	}

    #
    # now process optional elements
    #
    foreach $ce ( qw(
            baud
            ping
            respawn
            serial
            watchdog
            logfacility
            crm
    ) ) {
        if ($config->elementExists($valPath."/".$ce)) {
            $val=$config->getValue($valPath."/".$ce);
            $hacf.="$ce $val\n";
        }
    }

	# iterate over nodes. Right now there should be exactly two nodes.
	# however, implementing it as a list prepares for the future.
	#
	# also creates @node_list for reference later in unicast comms (below)
	#
	unless ($config->elementExists($valPath."/nodes")) {
		$self->error("mandatory config element $re not found!");
		return;
	}
	$re=$config->getElement($valPath."/nodes");
	while ($re->hasNextElement()) {
		$ce=$re->getNextElement();
		$val=$ce->getValue();
		$hacf.="node $val\n";
		push(@node_list,$val);
	}

	# set up communication between the nodes. there are two cases
	# enabled, namely, 'bcast' and 'ucast'. There can by >=2 of these.
	#
	$re=$config->getElement($valPath."/communication");
	while ($re->hasNextElement()) {
		$ce=$re->getNextElement();
		my $method=$ce->getValue();	# communication method (ucast, bcast,...)
		$ce=$re->getNextElement();
		my $interface=$ce->getValue();	# network interface name
		#
		my $nodename;	# member of the peer list in the cluster
		my $nodeip;	# IP address for $nodename
		#
		# the easy case: broadcast link (private interface, right?)
		#
		if ($method eq "bcast") {
			$hacf.="bcast $interface\n";
		#
		# unicast link: need to figure out IP addresses..
		# unicasts going to the local node are ignored, so it's safe to have
		# the same config file on all cluster members.
		#
		} elsif ($method eq "ucast") {
			foreach $nodename (@node_list) {
				$nodeip=inet_ntoa(scalar(gethostbyname($nodename)));
				$hacf.="ucast $interface $nodeip\n";
			}
		#
		# any other: save it for later (Fibre Channel, serial...)
		#
		} else {
			$self->error("unsupported (by ncm-linuxha) communication method '$method'");
			return;
		}
	}


#### authkeys #### 

	my $old_authkeys=LC::File::file_contents("/etc/ha.d/authkeys");
	if (not $old_authkeys) { $old_authkeys=" "; }
	my $authkeys="###\n### NCM-autogenerated\n### Do not edit but run ncm_wrapper.sh --co linuxha\n ###\nauth 1\n1 ";
	
	#
	# give the communication's preshared key to all cluster members
	# 
	unless ($config->elementExists($valPath."/authkey")) {
		$self->error("mandatory config element $ce not found!");
		return;
	}
	$val=$config->getValue($valPath."/authkey");
	$authkeys.=$val."\n";

#### haresources ####

	#
	# the resources file is a list of lists, each consisting of
	# a master node name and a list of resources that will fail over to the
	# 'other' node if the master node dies.
	#
	# ORDER DOES MATTER - services are started and stopped in this order
	#
	# this file is also (normally) identical among cluster members
	#

	my $old_haresources=LC::File::file_contents("/etc/ha.d/haresources");
	if (not $old_haresources) { $old_haresources=" "; }

	my $nowstamp=scalar localtime;
	my $haresources="###\n### NCM-autogenerated ###\n### Do not edit but run ncm_wrappers.sh --co linuxha\n###\n"; # assembled haresources file contents
	
	$re=$config->getElement($valPath."/resources");
	if (!defined($re)) {
		$self->error("mandatory config element resources not found");
		return;
	}
	while ($re->hasNextElement()) {
		my $reslist=$re->getNextElement(); # this is the subtree
		my @resline; # assembled resource line (array of its elements)
		# 
		# walk the resource list which is the subtree here
		#
		while ($reslist->hasNextElement()) {
				push(@resline,$reslist->getNextElement()->getValue());
		}
		$haresources.=join(" ",@resline)."\n";
	}

#####################

	#
	# if there's nothing to do, return without writing the files and
	# without reloading
	#
	if (	($old_hacf eq $hacf) &&
		($old_authkeys eq $authkeys) &&
		($old_haresources eq $haresources)	) {

		#print "XXX nothing to do! XXX \n";
		return;
	}	
	
	unless (LC::File::file_contents("/etc/ha.d/ha.cf",$hacf)) {
		$self->error("Can't write /etc/ha.d/ha.cf");
		return;
	}
	unless (LC::File::file_contents("/etc/ha.d/haresources",$haresources)) {
		$self->error("Can't write /etc/ha.d/haresources");
		return;
	}
	unless (LC::File::file_contents("/etc/ha.d/authkeys",$authkeys)) {
		$self->error("Can't write /etc/ha.d/authkeys");
		return;
	}
	chmod(0600,'/etc/ha.d/authkeys');

	unless (LC::Process::run('/sbin/service heartbeat reload')) {
		$self->error('command "/sbin/service heartbeat reload" failed');
		return;
	}

	return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules