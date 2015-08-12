object template attribute;

"/metaconfig/module" = "ganesha/2.2/main";
prefix "/metaconfig/contents/main/test";

# generated by `cat metaconfig/ganesha/pan/schema_v2.pan | grep ' [?:] .*=' | awk -F'( [?:=] |with| {4})' '{print $2 " = " $4 ";"}'`

"_9P_RDMA_Backlog" = 10;
"_9P_RDMA_Inpool_size" = 64;
"_9P_RDMA_Msize" = 1048576;
"_9P_RDMA_Outpool_Size" = 32;
"_9P_RDMA_Port" = 5640;
"_9P_TCP_Msize" = 65536;
"_9P_TCP_Port" = 564;
"Attr_Expiration_Time" = 60;
"Biggest_Window" = 40;
"Cache_FDs" = true;
"Entries_HWMark" = 100000;
"FD_HWMark_Percent" = 90;
"FD_LWMark_Percent" = 50;
"FD_Limit_Percent" = 99;
"Futility_Count" = 8;
"LRU_Run_Interval" = 90;
"NParts" = 7;
"Reaper_Work" = 1000;
"Required_Progress" = 5;
"Retry_Readdir" = false;
"Use_Getattr_Directory_Invalidation" = false;
"Stripe_Unit" = 8192;
"pnfs_enabled" = false;
"pnfs" = false;
"glfs_log" = "/tmp/gfapi.log";
"volpath" = "/";
"zpool" = "tank";
"pt_export_id" = 1;
"Access_Type" = 'None' ;
"Anonymous_gid" = -2;
"Anonymous_uid" = -2;
"Disable_ACL" = false;
"DisableReaddirPlus" = false;
"Manage_Gids" = false;
"NFS_Commit" = false;
"PrivilegedPort" = false;
"Protocols" = list('3', '4', '9P');
"SecType" = list('none', 'sys');
"Squash" = "root_squash" ;
"Transports" = list('UDP', 'TCP');
"Trust_Readdir_Negative_Cache" = false;
"Number" = 0;
"Attr_Expiration_Time" = 60;
"Filesystem_id" = "666.666";
"MaxRead" = 67108864;
"MaxWrite" = 67108864;
"PrefRead" = 67108864;
"PrefReaddir" = 16384;
"PrefWrite" = 67108864;
"UseCookieVerifier" = true;
"CLIENTIP" = false;
"COMPONENT" = true;
"EPOCH" = true;
"FILE_NAME" = true;
"FUNCTION_NAME" = true;
"HOSTNAME" = true;
"LEVEL" = true;
"LINE_NUM" = true;
"PID" = true;
"PROGNAME" = true;
"THREAD_NAME" = true;
"date_format" = 'ganesha';
"time_format" = 'ganesha';
"enable" = 'idle' ;
"headers" = 'all' ;
"max_level" = 'FULL_DEBUG';
"Default_log_level" = 'EVENT';
"Expiration_Time" = 3600;
"Index_Size" = 17;
"Active_krb5" = true;
"CCacheDir" = "/var/run/ganesha";
"KeytabPath" = "";
"PrincipalName" = "nfs";
"Allow_Numeric_Owners" = true;
"Delegations" = false;
"DomainName" = "localdomain";
"FSAL_Grace" = false;
"Grace_Period" = 90;
"Graceless" = false;
"IdmapConf" = "/etc/idmapd.conf";
"Lease_Lifetime" = 60;
"Bind_Addr" = "0.0.0.0";
"Clustered" = true;
"DRC_Disabled" = false;
"DRC_TCP_Cachesz" = 127;
"DRC_TCP_Checksum" = true;
"DRC_TCP_Hiwat" = 64;
"DRC_TCP_Npart" = 7;
"DRC_TCP_Recycle_Expire_S" = 600;
"DRC_TCP_Recycle_Npart" = 7;
"DRC_TCP_Size" = 1024;
"DRC_UDP_Cachesz" = 599;
"DRC_UDP_Checksum" = true;
"DRC_UDP_Hiwat" = 16384;
"DRC_UDP_Npart" = 7;
"DRC_UDP_Size" = 32768;
"Decoder_Fridge_Block_Timeout" = 600;
"Decoder_Fridge_Expiration_Delay" = 600;
"Dispatch_Max_Reqs" = 5000;
"Dispatch_Max_Reqs_Xprt" = 512;
"Drop_Delay_Errors" = false;
"Drop_IO_Errors" = false;
"Drop_Inval_Errors" = false;
"Enable_Fast_Stats" = false;
"Enable_NLM" = true;
"Enable_RQUOTA" = true;
"MNT_Port" = 0;
"MNT_Program" = 100005;
"Manage_Gids_Expiration" = 30*60;
"MaxRPCRecvBufferSize" = 1048576;
"MaxRPCSendBufferSize" = 1048576;
"NFS_Port" = 2049;
"NFS_Program" = 100003;
"NFS_Protocols" = list(3,4);
"NLM_Port" = 0;
"NLM_Program" = 100021;
"NSM_Use_Caller_Name" = false;
"Nb_Worker" = 16;
"Plugins_Dir" = "/usr/lib64/ganesha";
"RPC_Debug_Flags" = 0;
"RPC_Idle_Timeout_S" = 300;
"RPC_Ioq_ThrdMax" = 200;
"RPC_Max_Connections" = 1024;
"Rquota_Port" = 0;
"Rquota_Program" = 100011;
"Active_krb5" = false;
"Credential_LifeTime" = 86400;
"Enable_Handle_Mapping" = false;
"HandleMap_DB_Count" = 8;
"HandleMap_DB_Dir" = "/var/ganesha/handlemap";
"HandleMap_HashTable_Size" = 103;
"HandleMap_Tmp_Dir" = "/var/ganesha/tmp";
"KeytabPath" = "/etc/krb5.keytab";
"NFS_Port" = 2049;
"NFS_RecvSize" = 32768;
"NFS_SendSize" = 32768;
"NFS_Service" = 100003;
"RPC_Client_Timeout" = 60;
"Retry_SleepTime" = 10;
"Sec_Type" = 'krb5' ;
"Srv_Addr" = "127.0.0.1";
"Use_Privileged_Client_Port" = false;
"auth_xdev_export" = false;
"cansettime" = true;
"link_support" = true;
"symlink_support" = true;
"umask" = 0;
"xattr_access_rights" = '0400';
"maxread" = 67108864;
"maxwrite" = 67108864;
"fsal_grace" = false;
"fsal_trace" = true;
"pnfs_file" = false;
"DS_Addr" = "127.0.0.1";
"DS_Id" = 1;
"DS_Port" = 3260;

prefix "/metaconfig/contents/main/FSAL";
"PNFS/pnfs_enabled" = true; 