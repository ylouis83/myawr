#!/usr/bin/perl
#****************************************************************#
# ScriptName: mysqlawrrpt.pl
# Create Date: 2014-08-18 14:25
# Modify Date: 2014-08-18 14:25
#***************************************************************#

use strict;
use warnings;
use Getopt::Long;     
use POSIX qw(strftime);     
use Socket;    
use Carp qw(croak);
use DBI qw(:sql_types);
use Fcntl qw(:flock);
use IO::Handle;

Getopt::Long::Configure qw(no_ignore_case);    

my %opt;
  

( my $script_name = $0 ) =~ s!.*/(.*)!$1!;
my $lock_handle = _obtain_lock($script_name);


# Options
#----->
my $tid;
my $port = 3306;              
my $user = "user";
my $pswd;
my $lhost;
my $tport;

my $rprint = 60;

my $iscontinue=0;
my $myawrrpt_head=
'<html lang="en"><head><title>MySQL WorkLoad Report</title>
<style type="text/css">
/* roScripts
Table Design by Mihalcea Romeo
www.roscripts.com
----------------------------------------------- */
table { border-collapse:collapse;
		background:#EFF4FB url(http://www.roscripts.com/images/teaser.gif) repeat-x;
		border-left:1px solid #686868;
		border-right:1px solid #686868;
		font:0.8em/145% "Trebuchet MS",helvetica,arial,verdana;
		color: #333;}
td, th {padding:1px;}
caption {padding: 0 0 .5em 0;
		text-align: left;
		font-size: 1.4em;
		font-weight: bold;
		text-transform: uppercase;
		color: #333;
		background: transparent;}
/* =links----------------------------------------------- */
table a {color:#950000;	text-decoration:none;}
table a:link {}
table a:visited {font-weight:normal;color:#666;text-decoration: line-through;}
table a:hover {	border-bottom: 1px dashed #bbb;}
/* =head =foot----------------------------------------------- */
thead th, tfoot th, tfoot td {background:#333 url(http://www.roscripts.com/images/llsh.gif) repeat-x;color:#fff}
tfoot td {		text-align:right}
/* =body----------------------------------------------- */
tbody th, tbody td {border-bottom: dotted 1px #333;}
tbody th {white-space: nowrap;}
tbody th a {color:#333;}
.odd {}
tbody tr:hover {background:#fafafa}
</style></head><body>
<h1 >
Mysql WorkLoad Report
</h1>
<p /><hr />
';

my $myawrrpt_foot='<p /><h2>--------The      End -----------</h2></body></html>';

#<-----


my($host_name,$ip_addr,$port_num,$db_role,$version,$uptime);
my($start_snap_id,$end_snap_id,$rpt_file_name,$rcount,$start_snap_time,$end_snap_time,$start_unix_s,$end_unix_s,$snap_elapsed);
my($max_snap_id,$min_snap_id,$max_snap_time,$min_snap_time,$snap_interval,$max_unix_s,$mid_unix_s); 

my($start_query_cache_size,$start_thread_cache_size,$start_table_definition_cache,$start_max_connections,$start_table_open_cache,$start_slow_launch_time,$start_max_heap_table_size,$start_tmp_table_size,$start_open_files_limit,$start_Max_used_connections,$start_Threads_connected,$start_Threads_cached,$start_Threads_created,$start_Threads_running,$start_Connections,$start_Questions,$start_Com_select,$start_Com_insert,$start_Com_update,$start_Com_delete,$start_Bytes_received,$start_Bytes_sent,$start_Qcache_hits,$start_Qcache_inserts,$start_Select_full_join,$start_Select_scan,$start_Slow_queries,$start_Com_commit,$start_Com_rollback,$start_Open_files,$start_Open_table_definitions,$start_Open_tables,$start_Opened_files,$start_Opened_table_definitions,$start_Opened_tables,$start_Created_tmp_disk_tables,$start_Created_tmp_files,$start_Created_tmp_tables,$start_Binlog_cache_disk_use,$start_Binlog_cache_use,$start_Aborted_clients,$start_Sort_merge_passes,$start_Sort_range,$start_Sort_rows,$start_Sort_scan,$start_Table_locks_immediate,$start_Table_locks_waited,$start_Handler_read_first,$start_Handler_read_key,$start_Handler_read_last,$start_Handler_read_next,$start_Handler_read_prev,$start_Handler_read_rnd,$start_Handler_read_rnd_next);
my($start_Innodb_rows_inserted,$start_Innodb_rows_updated,$start_Innodb_rows_deleted,$start_Innodb_rows_read,$start_Innodb_buffer_pool_read_requests,$start_Innodb_buffer_pool_reads,$start_Innodb_buffer_pool_pages_data,$start_Innodb_buffer_pool_pages_free,$start_Innodb_buffer_pool_pages_dirty,$start_Innodb_buffer_pool_pages_flushed,$start_Innodb_data_reads,$start_Innodb_data_writes,$start_Innodb_data_read,$start_Innodb_data_written,$start_Innodb_os_log_fsyncs,$start_Innodb_os_log_written,$start_history_list,$start_log_bytes_written,$start_log_bytes_flushed,$start_last_checkpoint,$start_queries_inside,$start_queries_queued,$start_read_views,$start_innodb_open_files,$start_innodb_log_waits) ;
my($start_key_buffer_size,$start_join_buffer_size,$start_sort_buffer_size,$start_Key_blocks_not_flushed,$start_Key_blocks_unused,$start_Key_blocks_used,$start_Key_read_requests,$start_Key_reads,$start_Key_write_requests,$start_Key_writes);

my($end_query_cache_size,$end_thread_cache_size,$end_table_definition_cache,$end_max_connections,$end_table_open_cache,$end_slow_launch_time,$end_max_heap_table_size,$end_tmp_table_size,$end_open_files_limit,$end_Max_used_connections,$end_Threads_connected,$end_Threads_cached,$end_Threads_created,$end_Threads_running,$end_Connections,$end_Questions,$end_Com_select,$end_Com_insert,$end_Com_update,$end_Com_delete,$end_Bytes_received,$end_Bytes_sent,$end_Qcache_hits,$end_Qcache_inserts,$end_Select_full_join,$end_Select_scan,$end_Slow_queries,$end_Com_commit,$end_Com_rollback,$end_Open_files,$end_Open_table_definitions,$end_Open_tables,$end_Opened_files,$end_Opened_table_definitions,$end_Opened_tables,$end_Created_tmp_disk_tables,$end_Created_tmp_files,$end_Created_tmp_tables,$end_Binlog_cache_disk_use,$end_Binlog_cache_use,$end_Aborted_clients,$end_Sort_merge_passes,$end_Sort_range,$end_Sort_rows,$end_Sort_scan,$end_Table_locks_immediate,$end_Table_locks_waited,$end_Handler_read_first,$end_Handler_read_key,$end_Handler_read_last,$end_Handler_read_next,$end_Handler_read_prev,$end_Handler_read_rnd,$end_Handler_read_rnd_next);
my($end_Innodb_rows_inserted,$end_Innodb_rows_updated,$end_Innodb_rows_deleted,$end_Innodb_rows_read,$end_Innodb_buffer_pool_read_requests,$end_Innodb_buffer_pool_reads,$end_Innodb_buffer_pool_pages_data,$end_Innodb_buffer_pool_pages_free,$end_Innodb_buffer_pool_pages_dirty,$end_Innodb_buffer_pool_pages_flushed,$end_Innodb_data_reads,$end_Innodb_data_writes,$end_Innodb_data_read,$end_Innodb_data_written,$end_Innodb_os_log_fsyncs,$end_Innodb_os_log_written,$end_history_list,$end_log_bytes_written,$end_log_bytes_flushed,$end_last_checkpoint,$end_queries_inside,$end_queries_queued,$end_read_views,$end_innodb_open_files,$end_innodb_log_waits) ;
my($end_key_buffer_size,$end_join_buffer_size,$end_sort_buffer_size,$end_Key_blocks_not_flushed,$end_Key_blocks_unused,$end_Key_blocks_used,$end_Key_read_requests,$end_Key_reads,$end_Key_write_requests,$end_Key_writes);

my($tps,$sec_Com_select,$sec_Com_insert,$sec_Com_update,$sec_Com_delete,$Innodb_tps);
my($sec_Innodb_rows_inserted,$sec_Innodb_rows_updated,$sec_Innodb_rows_deleted,$sec_Innodb_data_reads,$sec_Innodb_data_read);
my($sec_Innodb_data_writes,$sec_Innodb_rows_read,$sec_Innodb_data_written,$sec_Innodb_os_log_fsyncs,$sec_Innodb_os_log_written);
my($sockets,$cores,$cpus,$platform,$memory);

sub _obtain_lock {
    my ($name) = @_;
    my $lock_dir  = $ENV{MYAWR_LOCK_DIR} || '/tmp';
    my $lock_file = "$lock_dir/$name.lock";
    open my $fh, '>', $lock_file or die "Cannot open lock file $lock_file: $!";
    unless (flock($fh, LOCK_EX | LOCK_NB)) {
        print STDERR "$name is already running.\n";
        exit 0;
    }
    $fh->autoflush(1);
    print {$fh} $$;
    return $fh;
}

sub connect_mysql {
    my (%args) = @_;
    for my $required (qw(database host port user password)) {
        croak "Missing required parameter '$required'" unless defined $args{$required};
    }
    my $dsn = sprintf 'DBI:mysql:database=%s;host=%s;port=%s',
      @args{qw(database host port)};
    my %attr = (
        RaiseError       => 1,
        PrintError       => 0,
        AutoCommit       => exists $args{autocommit} ? $args{autocommit} : 1,
        mysql_enable_utf8 => 1,
    );
    my $dbh = eval { DBI->connect_cached( $dsn, $args{user}, $args{password}, \%attr ) };
    if ( !$dbh ) {
        warn "Failed to connect to $dsn: " . ( $@ || $DBI::errstr );
        return;
    }
    return $dbh;
}

# Get options info
&get_options();

&get_snapinfo();


&get_myawrrpt() if $iscontinue==1;

# ----------------------------------------------------------------------------------------
# 
# Func :  print usage
# ----------------------------------------------------------------------------------------
sub print_usage {

	#print BLUE(),BOLD(),<<EOF,RESET();
	print <<EOF;

==========================================================================================
Info  :

===history 

myawrv1     By noodba (www.noodba.com).
myawrv2	-add multi instance     by louis 
myawrv3 -add formatted performance schema  by louis 
    

Reference: oradba  sys_schema  oracle_awr

Usage :
Command line options :

   -h,--help           Print Help Info. 
  
   -P,--port           Port number to use for local mysql connection(default 3306).
   -u,--user           user name for local mysql(default user).
   -p,--pswd           user password for local mysql(can't be null).
   -lh,--lhost         localhost(ip) for mysql where info is got(can't be null).

   -I,--tid            db instance register id(can't be null).    
   -T,--tport          db instance port (extend support multi instance can't be null) 
Sample :
   shell> perl myawrrpt.pl -p 111111 -lh 192.168.1.111 -I 11 -T 3309
==========================================================================================
EOF
	exit;
}

# ----------------------------------------------------------------------------------------
# 
# Func : get options and set option flag
# ----------------------------------------------------------------------------------------
sub get_options {

	# Get options info
	GetOptions(
		\%opt,
		'h|help',          # OUT : print help info
		'P|port=i',        # IN  : port
		'u|user=s',        # IN  : user
		'p|pswd=s',        # IN  : password
		'lh|lhost=s',      # IN  : host		
		'I|tid=i',         # IN  : instance id
		'T|tport=i',       # IN  : instance port
	) or print_usage();

	if ( !scalar(%opt) ) {
		&print_usage();
	}

	# Handle for options
	$opt{'h'}  and print_usage();
	$opt{'P'}  and $port = $opt{'P'};
	$opt{'u'}  and $user = $opt{'u'};
	$opt{'p'}  and $pswd = $opt{'p'};
	$opt{'lh'} and $lhost = $opt{'lh'};
	$opt{'I'}  and $tid = $opt{'I'};
    $opt{'T'} and $tport = $opt{'T'};
	if (
		!(
			defined $lhost
		    and defined $tid
		)
	  )
	{
		&print_usage();
	}
}


sub get_snapinfo {
    my $vars;
    my $sql;
    my $sth;
    
	my $dbh = connect_mysql(
		database   => 'dbmon',
		host       => $lhost,
		port       => $port,
		user       => $user,
		password   => $pswd,
		autocommit => 1,
	);
	exit if not $dbh;
    

	#get max(snap_id) and min(snap_id) and snap interval
	($max_snap_id,$min_snap_id)=$dbh->selectrow_array("select max(snap_id) max_snap_id ,min(snap_id) min_snap_id from dbmon.myawr_snapshot where host_id=$tid");
    ($host_name,$ip_addr,$port_num,$db_role,$version,$uptime)=$dbh->selectrow_array("select host_name,ip_addr,port,db_role,version,uptime from myawr_host where id=$tid");
    
    if(defined $max_snap_id and defined $min_snap_id  and $max_snap_id>=$min_snap_id+1){
    	
    	$sth = $dbh->prepare("select host_id,snap_id,snap_time,UNIX_TIMESTAMP(snap_time) unix_s from dbmon.myawr_snapshot where  host_id=$tid and snap_id in ($min_snap_id,$max_snap_id,$max_snap_id-1) order by snap_id asc");
		$sth->execute();
		if($max_snap_id==$min_snap_id+1){
			my @result = $sth->fetchrow_array ;
			$min_snap_time=$result[2];
			$mid_unix_s=$result[3];
			
			@result = $sth->fetchrow_array ;
			$max_snap_time=$result[2];
			$max_unix_s=$result[3];
			
			$snap_interval=$max_unix_s-$mid_unix_s;
		}else{
			my @result = $sth->fetchrow_array ;
			$min_snap_time=$result[2];
			
			@result = $sth->fetchrow_array ;
			my $mid_snap_time=$result[2];				
			$mid_unix_s=$result[3];
			
			@result = $sth->fetchrow_array ;
			$max_snap_time=$result[2];
			$max_unix_s=$result[3];
			
			$snap_interval=$max_unix_s-$mid_unix_s;	
		}

print  "===================================================\n";
print  "|       Welcome to use the myawrrpt tool !   \n";
print  "|             Date: ",strftime ("%Y-%m-%d", localtime) . "\n";
print  "|\n";
print  "|      Hostname is: $host_name "  . "\n";
print  "|       Ip addr is: $ip_addr "  . "\n";
print  "|          Port is: $port_num "  . "\n";
print  "|       Db role is: $db_role "  . "\n";
print  "|Server version is: $version"  . "\n";
print  "|        Uptime is: $uptime"  . "\n";
print  "|\n";
print  "|   Min snap_id is: $min_snap_id "  . "\n";
print  "| Min snap_time is: $min_snap_time "  . "\n";
print  "|   Max snap_id is: $max_snap_id "  . "\n";
print  "| Max snap_time is: $max_snap_time "  . "\n";
print  "| snap interval is: $snap_interval"  . "s\n";
print  "===================================================\n";	

print  "\n";

print  "Listing the last 2 days Snapshots\n";
print  "---------------------------------\n";	

        $rcount=$dbh->selectrow_array("select count(*) cnt from myawr_snapshot WHERE  snap_time>=date_add(\"$max_snap_time\", interval -2 day) and snap_time<=\"$max_snap_time\"  and host_id=$tid");
		my $rskip=$rcount/$rprint;
		
		$rskip=int($rskip+0.5);
		if($rskip< 1) {
			$rskip=1;
		}
				
		my $min_snap_dis=$max_snap_id-$rcount;
		my $n=$min_snap_dis;
		while($n < $max_snap_id){
			$sql =$sql. $n .",";
			$n= $n+ 0 +$rskip;
		}
		$sql.="$max_snap_id";
		
		$sth = $dbh->prepare("SELECT snap_id,snap_time from myawr_snapshot WHERE host_id=$tid and snap_time>=date_add(\"$max_snap_time\", interval -2 day) and snap_time<=\"$max_snap_time\" and snap_id in ($sql)");
		$sth->execute();
				
		while( my @result = $sth->fetchrow_array )	{
			printf  "snap_id: %7s      snap_time : $result[1] \n",   $result[0];				
		  }	
		  
print  "\n";
print  "Pls select Start and End Snapshot Id\n";
print  "------------------------------------\n";
print  "Enter value for start_snap:";		  		  
	
	#my($start_snap_id,$end_snap_id,$out_file_name,$rcount);	  		
		while (defined(my $line=<STDIN>)){
			if(int($line)>=$min_snap_id and int($line)<=$max_snap_id){
				$start_snap_id=int($line);
				print "Start Snapshot Id Is:" . $start_snap_id ."\n";
				last;
			}else{
				print  "Enter value for start_snap:";
			}
		}
		
print  "\n";
print  "Enter value for end_snap:";		
		while (defined(my $line=<STDIN>)){
			if(int($line)>=$min_snap_id and int($line)<=$max_snap_id and int($line)>$start_snap_id){
				$end_snap_id=int($line);
				print "End  Snapshot Id Is:" . $end_snap_id ."\n";
				last;
			}else{
				print  "Enter value for end_snap:";
			}
		}

print  "\n";
print  "Set the Report Name\n";
print  "-------------------\n";	

print  "\n";
print  "Enter value for report_name:";	
		while (defined(chomp(my $line=<STDIN>))){
			if(-e $line){
				print "A file called this name already exitsts!";
				print  "Enter value for report_name:";
			}else{
				$rpt_file_name=$line;
				last;
			}
		}							
print  "\n";
print  "Using the report name :$rpt_file_name\n";

$iscontinue=1;
		
    }else{
    	
    	$dbh->disconnect();
    	exit;
    }

    $sth->finish;
	$dbh->disconnect();
}

sub get_myawrrpt {
    my $vars;
    my $sql;
    my $sth;
    my $html_line;
	my $html_line1;
	$sockets = readpipe("cat /proc/cpuinfo | grep \"physical id\" | sort | uniq | wc -l");
	$cores = readpipe("grep \"^core id\" /proc/cpuinfo | sort -u  | wc -l")*2;
	$cpus = readpipe("cat /proc/cpuinfo |grep processor |wc -l");
	$platform = readpipe("uname -ms");
    $memory = sprintf("%.0f",readpipe("cat /proc/meminfo | grep MemTotal | awk \'{ print \$2 }\'")/1048576); 
	my $dbh = connect_mysql(
		database   => 'dbmon',
		host       => $lhost,
		port       => $port,
		user       => $user,
		password   => $pswd,
		autocommit => 1,
	);
	exit if not $dbh;
    
    print  "\n";
    print "Generating the mysql report for this analysis ...";
    
	open MYAWR_REPORT , "> $rpt_file_name" or die ("Can't open $rpt_file_name for write! /n");
	print MYAWR_REPORT $myawrrpt_head; 
	
	
	$html_line=
	"
<p />
<table border=\"1\"  width=\"600\">
<tr><th>Host Name</th><th>Ip addr</th><th>Port</th><th>Db role</th><th>Version</th><th>Uptime</th></tr>
<tr><td>$host_name</td><td>$ip_addr</td><td align=\"right\"> $port_num</td><td align=\"right\"> $db_role</td><td align=\"right\"> $version</td><td align=\"right\"> $uptime</td></tr>
</table><p />
<p />
<table border=\"2\"  width=\"600\">
<tr><th>Platform</th><th>cores</th><th>cpus</th><th>sockets</th><th>memory</th></tr>
<tr><td>$platform</td><td>$cores</td><td align=\"right\"> $cpus</td><td align=\"right\">$sockets</td><td align=\"right\"> $memory GB</td></tr>
</table><p />
	";
	print MYAWR_REPORT $html_line;

   	$sth = $dbh->prepare("select host_id,snap_id,snap_time,UNIX_TIMESTAMP(snap_time) unix_s from dbmon.myawr_snapshot where  host_id=$tid and snap_id in ($start_snap_id,$end_snap_id) order by snap_id asc");
	$sth->execute();

	my @result = $sth->fetchrow_array ;
	$start_snap_time=$result[2];
	$start_unix_s=$result[3];
	
	@result = $sth->fetchrow_array ;
	$end_snap_time=$result[2];
	$end_unix_s=$result[3];
	
	$snap_elapsed=$end_unix_s-$start_unix_s;


($start_query_cache_size,$start_thread_cache_size,$start_table_definition_cache,$start_max_connections,$start_table_open_cache,$start_slow_launch_time,$start_max_heap_table_size,$start_tmp_table_size,$start_open_files_limit,$start_Max_used_connections,$start_Threads_connected,$start_Threads_cached,$start_Threads_created,$start_Threads_running,$start_Connections,$start_Questions,$start_Com_select,$start_Com_insert,$start_Com_update,$start_Com_delete,$start_Bytes_received,$start_Bytes_sent,$start_Qcache_hits,$start_Qcache_inserts,$start_Select_full_join,$start_Select_scan,$start_Slow_queries,$start_Com_commit,$start_Com_rollback,$start_Open_files,$start_Open_table_definitions,$start_Open_tables,$start_Opened_files,$start_Opened_table_definitions,$start_Opened_tables,$start_Created_tmp_disk_tables,$start_Created_tmp_files,$start_Created_tmp_tables,$start_Binlog_cache_disk_use,$start_Binlog_cache_use,$start_Aborted_clients,$start_Sort_merge_passes,$start_Sort_range,$start_Sort_rows,$start_Sort_scan,$start_Table_locks_immediate,$start_Table_locks_waited,$start_Handler_read_first,$start_Handler_read_key,$start_Handler_read_last,$start_Handler_read_next,$start_Handler_read_prev,$start_Handler_read_rnd,$start_Handler_read_rnd_next)=$dbh->selectrow_array("select query_cache_size,thread_cache_size,table_definition_cache,max_connections,table_open_cache,slow_launch_time,max_heap_table_size,tmp_table_size,open_files_limit,Max_used_connections,Threads_connected,Threads_cached,Threads_created,Threads_running,Connections,Questions,Com_select,Com_insert,Com_update,Com_delete,Bytes_received,Bytes_sent,Qcache_hits,Qcache_inserts,Select_full_join,Select_scan,Slow_queries,Com_commit,Com_rollback,Open_files,Open_table_definitions,Open_tables,Opened_files,Opened_table_definitions,Opened_tables,Created_tmp_disk_tables,Created_tmp_files,Created_tmp_tables,Binlog_cache_disk_use,Binlog_cache_use,Aborted_clients,Sort_merge_passes,Sort_range,Sort_rows,Sort_scan,Table_locks_immediate,Table_locks_waited,Handler_read_first,Handler_read_key,Handler_read_last,Handler_read_next,Handler_read_prev,Handler_read_rnd,Handler_read_rnd_next from dbmon.myawr_mysql_info where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\"");
($start_Innodb_rows_inserted,$start_Innodb_rows_updated,$start_Innodb_rows_deleted,$start_Innodb_rows_read,$start_Innodb_buffer_pool_read_requests,$start_Innodb_buffer_pool_reads,$start_Innodb_buffer_pool_pages_data,$start_Innodb_buffer_pool_pages_free,$start_Innodb_buffer_pool_pages_dirty,$start_Innodb_buffer_pool_pages_flushed,$start_Innodb_data_reads,$start_Innodb_data_writes,$start_Innodb_data_read,$start_Innodb_data_written,$start_Innodb_os_log_fsyncs,$start_Innodb_os_log_written,$start_history_list,$start_log_bytes_written,$start_log_bytes_flushed,$start_last_checkpoint,$start_queries_inside,$start_queries_queued,$start_read_views,$start_innodb_open_files,$start_innodb_log_waits)=$dbh->selectrow_array("select Innodb_rows_inserted,Innodb_rows_updated,Innodb_rows_deleted,Innodb_rows_read,Innodb_buffer_pool_read_requests,Innodb_buffer_pool_reads,Innodb_buffer_pool_pages_data,  Innodb_buffer_pool_pages_free,  Innodb_buffer_pool_pages_dirty,  Innodb_buffer_pool_pages_flushed,  Innodb_data_reads,  Innodb_data_writes,  Innodb_data_read,  Innodb_data_written,  Innodb_os_log_fsyncs,  Innodb_os_log_written,  history_list,  log_bytes_written,  log_bytes_flushed,  last_checkpoint,  queries_inside,  queries_queued,  read_views, innodb_open_files,innodb_log_waits from dbmon.myawr_innodb_info where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\"");
($start_key_buffer_size,$start_join_buffer_size,$start_sort_buffer_size,$start_Key_blocks_not_flushed,$start_Key_blocks_unused,$start_Key_blocks_used,$start_Key_read_requests,$start_Key_reads,$start_Key_write_requests,$start_Key_writes)=$dbh->selectrow_array("select key_buffer_size,join_buffer_size,sort_buffer_size,Key_blocks_not_flushed,Key_blocks_unused,Key_blocks_used,Key_read_requests,Key_reads,Key_write_requests,Key_writes from dbmon.myawr_isam_info where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\"");

($end_query_cache_size,$end_thread_cache_size,$end_table_definition_cache,$end_max_connections,$end_table_open_cache,$end_slow_launch_time,$end_max_heap_table_size,$end_tmp_table_size,$end_open_files_limit,$end_Max_used_connections,$end_Threads_connected,$end_Threads_cached,$end_Threads_created,$end_Threads_running,$end_Connections,$end_Questions,$end_Com_select,$end_Com_insert,$end_Com_update,$end_Com_delete,$end_Bytes_received,$end_Bytes_sent,$end_Qcache_hits,$end_Qcache_inserts,$end_Select_full_join,$end_Select_scan,$end_Slow_queries,$end_Com_commit,$end_Com_rollback,$end_Open_files,$end_Open_table_definitions,$end_Open_tables,$end_Opened_files,$end_Opened_table_definitions,$end_Opened_tables,$end_Created_tmp_disk_tables,$end_Created_tmp_files,$end_Created_tmp_tables,$end_Binlog_cache_disk_use,$end_Binlog_cache_use,$end_Aborted_clients,$end_Sort_merge_passes,$end_Sort_range,$end_Sort_rows,$end_Sort_scan,$end_Table_locks_immediate,$end_Table_locks_waited,$end_Handler_read_first,$end_Handler_read_key,$end_Handler_read_last,$end_Handler_read_next,$end_Handler_read_prev,$end_Handler_read_rnd,$end_Handler_read_rnd_next)=$dbh->selectrow_array("select query_cache_size,thread_cache_size,table_definition_cache,max_connections,table_open_cache,slow_launch_time,max_heap_table_size,tmp_table_size,open_files_limit,Max_used_connections,Threads_connected,Threads_cached,Threads_created,Threads_running,Connections,Questions,Com_select,Com_insert,Com_update,Com_delete,Bytes_received,Bytes_sent,Qcache_hits,Qcache_inserts,Select_full_join,Select_scan,Slow_queries,Com_commit,Com_rollback,Open_files,Open_table_definitions,Open_tables,Opened_files,Opened_table_definitions,Opened_tables,Created_tmp_disk_tables,Created_tmp_files,Created_tmp_tables,Binlog_cache_disk_use,Binlog_cache_use,Aborted_clients,Sort_merge_passes,Sort_range,Sort_rows,Sort_scan,Table_locks_immediate,Table_locks_waited,Handler_read_first,Handler_read_key,Handler_read_last,Handler_read_next,Handler_read_prev,Handler_read_rnd,Handler_read_rnd_next from dbmon.myawr_mysql_info where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"");
($end_Innodb_rows_inserted,$end_Innodb_rows_updated,$end_Innodb_rows_deleted,$end_Innodb_rows_read,$end_Innodb_buffer_pool_read_requests,$end_Innodb_buffer_pool_reads,$end_Innodb_buffer_pool_pages_data,$end_Innodb_buffer_pool_pages_free,$end_Innodb_buffer_pool_pages_dirty,$end_Innodb_buffer_pool_pages_flushed,$end_Innodb_data_reads,$end_Innodb_data_writes,$end_Innodb_data_read,$end_Innodb_data_written,$end_Innodb_os_log_fsyncs,$end_Innodb_os_log_written,$end_history_list,$end_log_bytes_written,$end_log_bytes_flushed,$end_last_checkpoint,$end_queries_inside,$end_queries_queued,$end_read_views,$end_innodb_open_files,$end_innodb_log_waits)=$dbh->selectrow_array("select Innodb_rows_inserted,Innodb_rows_updated,Innodb_rows_deleted,Innodb_rows_read,Innodb_buffer_pool_read_requests,Innodb_buffer_pool_reads,Innodb_buffer_pool_pages_data,  Innodb_buffer_pool_pages_free,  Innodb_buffer_pool_pages_dirty,  Innodb_buffer_pool_pages_flushed,  Innodb_data_reads,  Innodb_data_writes,  Innodb_data_read,  Innodb_data_written,  Innodb_os_log_fsyncs,  Innodb_os_log_written,  history_list,  log_bytes_written,  log_bytes_flushed,  last_checkpoint,  queries_inside,  queries_queued,  read_views, innodb_open_files,innodb_log_waits from dbmon.myawr_innodb_info where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"");
($end_key_buffer_size,$end_join_buffer_size,$end_sort_buffer_size,$end_Key_blocks_not_flushed,$end_Key_blocks_unused,$end_Key_blocks_used,$end_Key_read_requests,$end_Key_reads,$end_Key_write_requests,$end_Key_writes)=$dbh->selectrow_array("select key_buffer_size,join_buffer_size,sort_buffer_size,Key_blocks_not_flushed,Key_blocks_unused,Key_blocks_used,Key_read_requests,Key_reads,Key_write_requests,Key_writes from dbmon.myawr_isam_info where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"");
	$html_line=
	"
<p />
<table border=\"1\"  width=\"600\">
<tr><th></th><th>Snap Id</th><th>Snap Time</th><th>Threads_connected</th><th>Threads_running</th></tr>
<tr><td>Begin Snap:</td><td align=\"right\">$start_snap_id</td><td align=\"center\">$start_snap_time</td><td align=\"right\">$start_Threads_connected</td><td align=\"right\"> $start_Threads_running</td></tr><tr><td>End Snap:</td><td align=\"right\">$end_snap_id</td><td align=\"center\">$end_snap_time</td><td align=\"right\">$end_Threads_connected</td><td align=\"right\"> $end_Threads_running</td></tr><tr><td>Elapsed:</td><td colspan=4 > $snap_elapsed (seconds)</td></tr>
</table><p />
	";
	
	print MYAWR_REPORT $html_line;
	
	$html_line=
	"
<h3 >Start snap value and end snap value</h3><p />
<table border=\"1\" width=\"600\">
<tr><th></th><th>Begin</th><th>End</th><th>Diff</th></tr>	
<tr><td>query_cache_size                :</td><td align=\"right\">$start_query_cache_size                </td><td align=\"right\">$end_query_cache_size                 </td><td align=\"right\">" . eval($end_query_cache_size                 - $start_query_cache_size                 ) ."</td></tr> 
<tr><td>thread_cache_size               :</td><td align=\"right\">$start_thread_cache_size               </td><td align=\"right\">$end_thread_cache_size                </td><td align=\"right\">" . eval($end_thread_cache_size                - $start_thread_cache_size                ) ."</td></tr> 
<tr><td>table_definition_cache          :</td><td align=\"right\">$start_table_definition_cache          </td><td align=\"right\">$end_table_definition_cache           </td><td align=\"right\">" . eval($end_table_definition_cache           - $start_table_definition_cache           ) . "</td></tr> 
<tr><td>max_connections                 :</td><td align=\"right\">$start_max_connections                 </td><td align=\"right\">$end_max_connections                  </td><td align=\"right\">" . eval($end_max_connections                  - $start_max_connections                  ) . "</td></tr> 
<tr><td>table_open_cache                :</td><td align=\"right\">$start_table_open_cache                </td><td align=\"right\">$end_table_open_cache                 </td><td align=\"right\">" . eval($end_table_open_cache                 - $start_table_open_cache                 ) . "</td></tr> 
<tr><td>slow_launch_time                :</td><td align=\"right\">$start_slow_launch_time                </td><td align=\"right\">$end_slow_launch_time                 </td><td align=\"right\">" . eval($end_slow_launch_time                 - $start_slow_launch_time                 ) . "</td></tr> 
<tr><td>max_heap_table_size             :</td><td align=\"right\">$start_max_heap_table_size             </td><td align=\"right\">$end_max_heap_table_size              </td><td align=\"right\">" . eval($end_max_heap_table_size              - $start_max_heap_table_size              ) . "</td></tr> 
<tr><td>tmp_table_size                  :</td><td align=\"right\">$start_tmp_table_size                  </td><td align=\"right\">$end_tmp_table_size                   </td><td align=\"right\">" . eval($end_tmp_table_size                   - $start_tmp_table_size                   ) . "</td></tr> 
<tr><td>open_files_limit                :</td><td align=\"right\">$start_open_files_limit                </td><td align=\"right\">$end_open_files_limit                 </td><td align=\"right\">" . eval($end_open_files_limit                 - $start_open_files_limit                 ) . "</td></tr> 
<tr><td>Max_used_connections            :</td><td align=\"right\">$start_Max_used_connections            </td><td align=\"right\">$end_Max_used_connections             </td><td align=\"right\">" . eval($end_Max_used_connections             - $start_Max_used_connections             ) . "</td></tr> 
<tr><td>Threads_connected               :</td><td align=\"right\">$start_Threads_connected               </td><td align=\"right\">$end_Threads_connected                </td><td align=\"right\">" . eval($end_Threads_connected                - $start_Threads_connected                ) . "</td></tr> 
<tr><td>Threads_cached                  :</td><td align=\"right\">$start_Threads_cached                  </td><td align=\"right\">$end_Threads_cached                   </td><td align=\"right\">" . eval($end_Threads_cached                   - $start_Threads_cached                   ) . "</td></tr> 
<tr><td>Threads_created                 :</td><td align=\"right\">$start_Threads_created                 </td><td align=\"right\">$end_Threads_created                  </td><td align=\"right\">" . eval($end_Threads_created                  - $start_Threads_created                  ) . "</td></tr> 
<tr><td>Threads_running                 :</td><td align=\"right\">$start_Threads_running                 </td><td align=\"right\">$end_Threads_running                  </td><td align=\"right\">" . eval($end_Threads_running                  - $start_Threads_running                  ) . "</td></tr> 
<tr><td>Connections                     :</td><td align=\"right\">$start_Connections                     </td><td align=\"right\">$end_Connections                      </td><td align=\"right\">" . eval($end_Connections                      - $start_Connections                      ) . "</td></tr> 
<tr><td>key_buffer_size                 :</td><td align=\"right\">$start_key_buffer_size                 </td><td align=\"right\">$end_key_buffer_size                  </td><td align=\"right\">" . eval($end_key_buffer_size                  - $start_key_buffer_size                  ) . "</td></tr> 
<tr><td>join_buffer_size                :</td><td align=\"right\">$start_join_buffer_size                </td><td align=\"right\">$end_join_buffer_size                 </td><td align=\"right\">" . eval($end_join_buffer_size                 - $start_join_buffer_size                 ) . "</td></tr> 
<tr><td>sort_buffer_size                :</td><td align=\"right\">$start_sort_buffer_size                </td><td align=\"right\">$end_sort_buffer_size                 </td><td align=\"right\">" . eval($end_sort_buffer_size                 - $start_sort_buffer_size                 ) . "</td></tr> 
<tr><td>Key_blocks_not_flushed          :</td><td align=\"right\">$start_Key_blocks_not_flushed          </td><td align=\"right\">$end_Key_blocks_not_flushed           </td><td align=\"right\">" . eval($end_Key_blocks_not_flushed           - $start_Key_blocks_not_flushed           ) . "</td></tr> 
<tr><td>Key_blocks_unused               :</td><td align=\"right\">$start_Key_blocks_unused               </td><td align=\"right\">$end_Key_blocks_unused                </td><td align=\"right\">" . eval($end_Key_blocks_unused                - $start_Key_blocks_unused                ) . "</td></tr> 
<tr><td>Key_blocks_used                 :</td><td align=\"right\">$start_Key_blocks_used                 </td><td align=\"right\">$end_Key_blocks_used                  </td><td align=\"right\">" . eval($end_Key_blocks_used                  - $start_Key_blocks_used                  ) . "</td></tr> 
<tr><td>Key_read_requests               :</td><td align=\"right\">$start_Key_read_requests               </td><td align=\"right\">$end_Key_read_requests                </td><td align=\"right\">" . eval($end_Key_read_requests                - $start_Key_read_requests                ) . "</td></tr> 
<tr><td>Key_reads                       :</td><td align=\"right\">$start_Key_reads                       </td><td align=\"right\">$end_Key_reads                        </td><td align=\"right\">" . eval($end_Key_reads                        - $start_Key_reads                        ) . "</td></tr> 
<tr><td>Key_write_requests              :</td><td align=\"right\">$start_Key_write_requests              </td><td align=\"right\">$end_Key_write_requests               </td><td align=\"right\">" . eval($end_Key_write_requests               - $start_Key_write_requests               ) . "</td></tr> 
<tr><td>Key_writes                      :</td><td align=\"right\">$start_Key_writes                      </td><td align=\"right\">$end_Key_writes                       </td><td align=\"right\">" . eval($end_Key_writes                       - $start_Key_writes                       ) . "</td></tr> 
<tr><td>Questions                       :</td><td align=\"right\">$start_Questions                       </td><td align=\"right\">$end_Questions                        </td><td align=\"right\">" . eval($end_Questions                        - $start_Questions                        ) . "</td></tr> 
<tr><td>Com_select                      :</td><td align=\"right\">$start_Com_select                      </td><td align=\"right\">$end_Com_select                       </td><td align=\"right\">" . eval($end_Com_select                       - $start_Com_select                       ) . "</td></tr> 
<tr><td>Com_insert                      :</td><td align=\"right\">$start_Com_insert                      </td><td align=\"right\">$end_Com_insert                       </td><td align=\"right\">" . eval($end_Com_insert                       - $start_Com_insert                       ) . "</td></tr> 
<tr><td>Com_update                      :</td><td align=\"right\">$start_Com_update                      </td><td align=\"right\">$end_Com_update                       </td><td align=\"right\">" . eval($end_Com_update                       - $start_Com_update                       ) . "</td></tr> 
<tr><td>Com_delete                      :</td><td align=\"right\">$start_Com_delete                      </td><td align=\"right\">$end_Com_delete                       </td><td align=\"right\">" . eval($end_Com_delete                       - $start_Com_delete                       ) . "</td></tr> 
<tr><td>Bytes_received                  :</td><td align=\"right\">$start_Bytes_received                  </td><td align=\"right\">$end_Bytes_received                   </td><td align=\"right\">" . eval($end_Bytes_received                   - $start_Bytes_received                   ) . "</td></tr> 
<tr><td>Bytes_sent                      :</td><td align=\"right\">$start_Bytes_sent                      </td><td align=\"right\">$end_Bytes_sent                       </td><td align=\"right\">" . eval($end_Bytes_sent                       - $start_Bytes_sent                       ) . "</td></tr> 
<tr><td>Qcache_hits                     :</td><td align=\"right\">$start_Qcache_hits                     </td><td align=\"right\">$end_Qcache_hits                      </td><td align=\"right\">" . eval($end_Qcache_hits                      - $start_Qcache_hits                      ) . "</td></tr> 
<tr><td>Qcache_inserts                  :</td><td align=\"right\">$start_Qcache_inserts                  </td><td align=\"right\">$end_Qcache_inserts                   </td><td align=\"right\">" . eval($end_Qcache_inserts                   - $start_Qcache_inserts                   ) . "</td></tr> 
<tr><td>Select_full_join                :</td><td align=\"right\">$start_Select_full_join                </td><td align=\"right\">$end_Select_full_join                 </td><td align=\"right\">" . eval($end_Select_full_join                 - $start_Select_full_join                 ) . "</td></tr> 
<tr><td>Select_scan                     :</td><td align=\"right\">$start_Select_scan                     </td><td align=\"right\">$end_Select_scan                      </td><td align=\"right\">" . eval($end_Select_scan                      - $start_Select_scan                      ) . "</td></tr> 
<tr><td>Slow_queries                    :</td><td align=\"right\">$start_Slow_queries                    </td><td align=\"right\">$end_Slow_queries                     </td><td align=\"right\">" . eval($end_Slow_queries                     - $start_Slow_queries                     ) . "</td></tr> 
<tr><td>Com_commit                      :</td><td align=\"right\">$start_Com_commit                      </td><td align=\"right\">$end_Com_commit                       </td><td align=\"right\">" . eval($end_Com_commit                       - $start_Com_commit                       ) . "</td></tr> 
<tr><td>Com_rollback                    :</td><td align=\"right\">$start_Com_rollback                    </td><td align=\"right\">$end_Com_rollback                     </td><td align=\"right\">" . eval($end_Com_rollback                     - $start_Com_rollback                     ) . "</td></tr> 
<tr><td>Open_files                      :</td><td align=\"right\">$start_Open_files                      </td><td align=\"right\">$end_Open_files                       </td><td align=\"right\">" . eval($end_Open_files                       - $start_Open_files                       ) . "</td></tr> 
<tr><td>Open_table_definitions          :</td><td align=\"right\">$start_Open_table_definitions          </td><td align=\"right\">$end_Open_table_definitions           </td><td align=\"right\">" . eval($end_Open_table_definitions           - $start_Open_table_definitions           ) . "</td></tr> 
<tr><td>Open_tables                     :</td><td align=\"right\">$start_Open_tables                     </td><td align=\"right\">$end_Open_tables                      </td><td align=\"right\">" . eval($end_Open_tables                      - $start_Open_tables                      ) . "</td></tr> 
<tr><td>Opened_files                    :</td><td align=\"right\">$start_Opened_files                    </td><td align=\"right\">$end_Opened_files                     </td><td align=\"right\">" . eval($end_Opened_files                     - $start_Opened_files                     ) . "</td></tr> 
<tr><td>Opened_table_definitions        :</td><td align=\"right\">$start_Opened_table_definitions        </td><td align=\"right\">$end_Opened_table_definitions         </td><td align=\"right\">" . eval($end_Opened_table_definitions         - $start_Opened_table_definitions         ) . "</td></tr> 
<tr><td>Opened_tables                   :</td><td align=\"right\">$start_Opened_tables                   </td><td align=\"right\">$end_Opened_tables                    </td><td align=\"right\">" . eval($end_Opened_tables                    - $start_Opened_tables                    ) . "</td></tr> 
<tr><td>Created_tmp_disk_tables         :</td><td align=\"right\">$start_Created_tmp_disk_tables         </td><td align=\"right\">$end_Created_tmp_disk_tables          </td><td align=\"right\">" . eval($end_Created_tmp_disk_tables          - $start_Created_tmp_disk_tables          ) . "</td></tr> 
<tr><td>Created_tmp_files               :</td><td align=\"right\">$start_Created_tmp_files               </td><td align=\"right\">$end_Created_tmp_files                </td><td align=\"right\">" . eval($end_Created_tmp_files                - $start_Created_tmp_files                ) . "</td></tr> 
<tr><td>Created_tmp_tables              :</td><td align=\"right\">$start_Created_tmp_tables              </td><td align=\"right\">$end_Created_tmp_tables               </td><td align=\"right\">" . eval($end_Created_tmp_tables               - $start_Created_tmp_tables               ) . "</td></tr> 
<tr><td>Binlog_cache_disk_use           :</td><td align=\"right\">$start_Binlog_cache_disk_use           </td><td align=\"right\">$end_Binlog_cache_disk_use            </td><td align=\"right\">" . eval($end_Binlog_cache_disk_use            - $start_Binlog_cache_disk_use            ) . "</td></tr> 
<tr><td>Binlog_cache_use                :</td><td align=\"right\">$start_Binlog_cache_use                </td><td align=\"right\">$end_Binlog_cache_use                 </td><td align=\"right\">" . eval($end_Binlog_cache_use                 - $start_Binlog_cache_use                 ) . "</td></tr> 
<tr><td>Aborted_clients                 :</td><td align=\"right\">$start_Aborted_clients                 </td><td align=\"right\">$end_Aborted_clients                  </td><td align=\"right\">" . eval($end_Aborted_clients                  - $start_Aborted_clients                  ) . "</td></tr> 
<tr><td>Sort_merge_passes               :</td><td align=\"right\">$start_Sort_merge_passes               </td><td align=\"right\">$end_Sort_merge_passes                </td><td align=\"right\">" . eval($end_Sort_merge_passes                - $start_Sort_merge_passes                ) . "</td></tr> 
<tr><td>Sort_range                      :</td><td align=\"right\">$start_Sort_range                      </td><td align=\"right\">$end_Sort_range                       </td><td align=\"right\">" . eval($end_Sort_range                       - $start_Sort_range                       ) . "</td></tr> 
<tr><td>Sort_rows                       :</td><td align=\"right\">$start_Sort_rows                       </td><td align=\"right\">$end_Sort_rows                        </td><td align=\"right\">" . eval($end_Sort_rows                        - $start_Sort_rows                        ) . "</td></tr> 
<tr><td>Sort_scan                       :</td><td align=\"right\">$start_Sort_scan                       </td><td align=\"right\">$end_Sort_scan                        </td><td align=\"right\">" . eval($end_Sort_scan                        - $start_Sort_scan                        ) . "</td></tr> 
<tr><td>Table_locks_immediate           :</td><td align=\"right\">$start_Table_locks_immediate           </td><td align=\"right\">$end_Table_locks_immediate            </td><td align=\"right\">" . eval($end_Table_locks_immediate            - $start_Table_locks_immediate            ) . "</td></tr> 
<tr><td>Table_locks_waited              :</td><td align=\"right\">$start_Table_locks_waited              </td><td align=\"right\">$end_Table_locks_waited               </td><td align=\"right\">" . eval($end_Table_locks_waited               - $start_Table_locks_waited               ) . "</td></tr> 
<tr><td>Handler_read_first              :</td><td align=\"right\">$start_Handler_read_first              </td><td align=\"right\">$end_Handler_read_first               </td><td align=\"right\">" . eval($end_Handler_read_first               - $start_Handler_read_first               ) . "</td></tr> 
<tr><td>Handler_read_key                :</td><td align=\"right\">$start_Handler_read_key                </td><td align=\"right\">$end_Handler_read_key                 </td><td align=\"right\">" . eval($end_Handler_read_key                 - $start_Handler_read_key                 ) . "</td></tr> 
<tr><td>Handler_read_last               :</td><td align=\"right\">$start_Handler_read_last               </td><td align=\"right\">$end_Handler_read_last                </td><td align=\"right\">" . eval($end_Handler_read_last                - $start_Handler_read_last                ) . "</td></tr> 
<tr><td>Handler_read_next               :</td><td align=\"right\">$start_Handler_read_next               </td><td align=\"right\">$end_Handler_read_next                </td><td align=\"right\">" . eval($end_Handler_read_next                - $start_Handler_read_next                ) . "</td></tr> 
<tr><td>Handler_read_prev               :</td><td align=\"right\">$start_Handler_read_prev               </td><td align=\"right\">$end_Handler_read_prev                </td><td align=\"right\">" . eval($end_Handler_read_prev                - $start_Handler_read_prev                ) . "</td></tr> 
<tr><td>Handler_read_rnd                :</td><td align=\"right\">$start_Handler_read_rnd                </td><td align=\"right\">$end_Handler_read_rnd                 </td><td align=\"right\">" . eval($end_Handler_read_rnd                 - $start_Handler_read_rnd                 ) . "</td></tr> 
<tr><td>Innodb_rows_updated             :</td><td align=\"right\">$start_Innodb_rows_updated             </td><td align=\"right\">$end_Innodb_rows_updated              </td><td align=\"right\">" . eval($end_Innodb_rows_updated              - $start_Innodb_rows_updated              ) . "</td></tr> 
<tr><td>Innodb_rows_deleted             :</td><td align=\"right\">$start_Innodb_rows_deleted             </td><td align=\"right\">$end_Innodb_rows_deleted              </td><td align=\"right\">" . eval($end_Innodb_rows_deleted              - $start_Innodb_rows_deleted              ) . "</td></tr> 
<tr><td>Innodb_rows_read                :</td><td align=\"right\">$start_Innodb_rows_read                </td><td align=\"right\">$end_Innodb_rows_read                 </td><td align=\"right\">" . eval($end_Innodb_rows_read                 - $start_Innodb_rows_read                 ) . "</td></tr> 
<tr><td>Innodb_buffer_pool_read_requests:</td><td align=\"right\">$start_Innodb_buffer_pool_read_requests</td><td align=\"right\">$end_Innodb_buffer_pool_read_requests </td><td align=\"right\">" . eval($end_Innodb_buffer_pool_read_requests - $start_Innodb_buffer_pool_read_requests ) . "</td></tr> 
<tr><td>Innodb_buffer_pool_reads        :</td><td align=\"right\">$start_Innodb_buffer_pool_reads        </td><td align=\"right\">$end_Innodb_buffer_pool_reads         </td><td align=\"right\">" . eval($end_Innodb_buffer_pool_reads         - $start_Innodb_buffer_pool_reads         ) . "</td></tr> 
<tr><td>Innodb_buffer_pool_pages_data   :</td><td align=\"right\">$start_Innodb_buffer_pool_pages_data   </td><td align=\"right\">$end_Innodb_buffer_pool_pages_data    </td><td align=\"right\">" . eval($end_Innodb_buffer_pool_pages_data    - $start_Innodb_buffer_pool_pages_data    ) . "</td></tr> 
<tr><td>Innodb_buffer_pool_pages_free   :</td><td align=\"right\">$start_Innodb_buffer_pool_pages_free   </td><td align=\"right\">$end_Innodb_buffer_pool_pages_free    </td><td align=\"right\">" . eval($end_Innodb_buffer_pool_pages_free    - $start_Innodb_buffer_pool_pages_free    ) . "</td></tr> 
<tr><td>Innodb_buffer_pool_pages_dirty  :</td><td align=\"right\">$start_Innodb_buffer_pool_pages_dirty  </td><td align=\"right\">$end_Innodb_buffer_pool_pages_dirty   </td><td align=\"right\">" . eval($end_Innodb_buffer_pool_pages_dirty   - $start_Innodb_buffer_pool_pages_dirty   ) . "</td></tr> 
<tr><td>Innodb_buffer_pool_pages_flushed:</td><td align=\"right\">$start_Innodb_buffer_pool_pages_flushed</td><td align=\"right\">$end_Innodb_buffer_pool_pages_flushed </td><td align=\"right\">" . eval($end_Innodb_buffer_pool_pages_flushed - $start_Innodb_buffer_pool_pages_flushed ) . "</td></tr> 
<tr><td>Innodb_data_reads               :</td><td align=\"right\">$start_Innodb_data_reads               </td><td align=\"right\">$end_Innodb_data_reads                </td><td align=\"right\">" . eval($end_Innodb_data_reads                - $start_Innodb_data_reads                ) . "</td></tr> 
<tr><td>Innodb_data_writes              :</td><td align=\"right\">$start_Innodb_data_writes              </td><td align=\"right\">$end_Innodb_data_writes               </td><td align=\"right\">" . eval($end_Innodb_data_writes               - $start_Innodb_data_writes               ) . "</td></tr> 
<tr><td>Innodb_data_read                :</td><td align=\"right\">$start_Innodb_data_read                </td><td align=\"right\">$end_Innodb_data_read                 </td><td align=\"right\">" . eval($end_Innodb_data_read                 - $start_Innodb_data_read                 ) . "</td></tr> 
<tr><td>Innodb_data_written             :</td><td align=\"right\">$start_Innodb_data_written             </td><td align=\"right\">$end_Innodb_data_written              </td><td align=\"right\">" . eval($end_Innodb_data_written              - $start_Innodb_data_written              ) . "</td></tr> 
<tr><td>Innodb_os_log_fsyncs            :</td><td align=\"right\">$start_Innodb_os_log_fsyncs            </td><td align=\"right\">$end_Innodb_os_log_fsyncs             </td><td align=\"right\">" . eval($end_Innodb_os_log_fsyncs             - $start_Innodb_os_log_fsyncs             ) . "</td></tr> 
<tr><td>Innodb_os_log_written           :</td><td align=\"right\">$start_Innodb_os_log_written           </td><td align=\"right\">$end_Innodb_os_log_written            </td><td align=\"right\">" . eval($end_Innodb_os_log_written            - $start_Innodb_os_log_written            ) . "</td></tr> 
<tr><td>history_list                    :</td><td align=\"right\">$start_history_list                    </td><td align=\"right\">$end_history_list                     </td><td align=\"right\">" . eval($end_history_list                     - $start_history_list                     ) . "</td></tr> 
<tr><td>log_bytes_written               :</td><td align=\"right\">$start_log_bytes_written               </td><td align=\"right\">$end_log_bytes_written                </td><td align=\"right\">" . eval($end_log_bytes_written                - $start_log_bytes_written                ) . "</td></tr> 
<tr><td>log_bytes_flushed               :</td><td align=\"right\">$start_log_bytes_flushed               </td><td align=\"right\">$end_log_bytes_flushed                </td><td align=\"right\">" . eval($end_log_bytes_flushed                - $start_log_bytes_flushed                ) . "</td></tr> 
<tr><td>last_checkpoint                 :</td><td align=\"right\">$start_last_checkpoint                 </td><td align=\"right\">$end_last_checkpoint                  </td><td align=\"right\">" . eval($end_last_checkpoint                  - $start_last_checkpoint                  ) . "</td></tr> 
<tr><td>queries_inside                  :</td><td align=\"right\">$start_queries_inside                  </td><td align=\"right\">$end_queries_inside                   </td><td align=\"right\">" . eval($end_queries_inside                   - $start_queries_inside                   ) . "</td></tr> 
<tr><td>queries_queued                  :</td><td align=\"right\">$start_queries_queued                  </td><td align=\"right\">$end_queries_queued                   </td><td align=\"right\">" . eval($end_queries_queued                   - $start_queries_queued                   ) . "</td></tr> 
<tr><td>read_views                      :</td><td align=\"right\">$start_read_views                      </td><td align=\"right\">$end_read_views                       </td><td align=\"right\">" . eval($end_read_views                       - $start_read_views                       ) . "</td></tr> 
<tr><td>innodb_open_files               :</td><td align=\"right\">$start_innodb_open_files               </td><td align=\"right\">$end_innodb_open_files                </td><td align=\"right\">" . eval($end_innodb_open_files                - $start_innodb_open_files                ) . "</td></tr> 
<tr><td>innodb_log_waits                :</td><td align=\"right\">$start_innodb_log_waits                </td><td align=\"right\">$end_innodb_log_waits                 </td><td align=\"right\">" . eval($end_innodb_log_waits                 - $start_innodb_log_waits                 ) . "</td></tr>

</table><p />
";	
	print MYAWR_REPORT $html_line;
    print MYAWR_REPORT "<hr />\n";
	
$tps=int((($end_Com_insert -$start_Com_insert)+($end_Com_update -$start_Com_update)+($end_Com_delete -$start_Com_delete))/$snap_elapsed) ;	
$sec_Com_select=int(($end_Com_select -$start_Com_select)/$snap_elapsed) ;	
$sec_Com_insert=int( ($end_Com_insert -$start_Com_insert)/$snap_elapsed ) ;	
$sec_Com_update=int(($end_Com_update -$start_Com_update)/$snap_elapsed ) ;	
$sec_Com_delete=int(($end_Com_delete -$start_Com_delete)/$snap_elapsed ) ;	
$Innodb_tps=int((($end_Innodb_rows_inserted -$start_Innodb_rows_inserted)+ ($end_Innodb_rows_updated -$start_Innodb_rows_updated)+($end_Innodb_rows_deleted -$start_Innodb_rows_deleted))/$snap_elapsed) ;

$sec_Innodb_rows_inserted=int( ($end_Innodb_rows_inserted -$start_Innodb_rows_inserted)/$snap_elapsed) ;	
$sec_Innodb_rows_updated=int(($end_Innodb_rows_updated -$start_Innodb_rows_updated)/$snap_elapsed) ;	
$sec_Innodb_rows_deleted=int(($end_Innodb_rows_deleted -$start_Innodb_rows_deleted)/$snap_elapsed ) ;	
$sec_Innodb_rows_read=int(($end_Innodb_rows_read -$start_Innodb_rows_read)/$snap_elapsed) ;	

$sec_Innodb_data_reads=int(($end_Innodb_data_reads -$start_Innodb_data_reads)/$snap_elapsed) ;	
$sec_Innodb_data_writes=int( ($end_Innodb_data_writes -$start_Innodb_data_writes)/$snap_elapsed) ;	


$sec_Innodb_data_written=int( ($end_Innodb_data_written -$start_Innodb_data_written)/$snap_elapsed/1024) ;	
$sec_Innodb_data_read=int( ($end_Innodb_data_read -$start_Innodb_data_read)/$snap_elapsed/1024) ;	
$sec_Innodb_os_log_fsyncs=int( ($end_Innodb_os_log_fsyncs -$start_Innodb_os_log_fsyncs)/$snap_elapsed ) ;	
$sec_Innodb_os_log_written=int(  ($end_Innodb_os_log_written -$start_Innodb_os_log_written)/$snap_elapsed/1024) ;

	$html_line =
	"
<p/><h3>Some Key Load Info</h3>  <p />
<table border=\"1\" width=\"600\">
<tr><th></th><th>Per Second</th></tr>
<tr><td>TPS:</td><td align=\"right\"> $tps</td></tr>
<tr><td>Com_select(s):</td><td align=\"right\"> $sec_Com_select </td></tr>
<tr><td>Com_insert(s):</td><td align=\"right\"> $sec_Com_insert</td></tr>
<tr><td>Com_update(s):</td><td align=\"right\"> $sec_Com_update</td></tr>
<tr><td>Com_delete(s):</td><td align=\"right\"> $sec_Com_delete</td></tr>
<tr><td>Innodb t_row PS:</td><td align=\"right\"> $Innodb_tps </td></tr>

<tr><td>Innodb_rows_inserted(s):</td><td align=\"right\">$sec_Innodb_rows_inserted </td></tr>
<tr><td>Innodb_rows_updated(s):</td><td align=\"right\"> $sec_Innodb_rows_updated </td></tr>
<tr><td>Innodb_rows_deleted(s):</td><td align=\"right\"> $sec_Innodb_rows_deleted</td></tr>
<tr><td>Innodb_rows_read(s):</td><td align=\"right\"> $sec_Innodb_rows_read </td></tr>

<tr><td>Innodb_data_reads(s):</td><td align=\"right\"> $sec_Innodb_data_reads </td></tr>
<tr><td>Innodb_data_writes(s):</td><td align=\"right\"> $sec_Innodb_data_writes</td></tr>

<tr><td>Innodb_data_read(kb/s):</td><td align=\"right\">$sec_Innodb_data_read </td></tr>
<tr><td>Innodb_data_written(kb/s):</td><td align=\"right\">$sec_Innodb_data_written </td></tr>

<tr><td>Innodb_os_log_fsyncs(s):</td><td align=\"right\">$sec_Innodb_os_log_fsyncs </td></tr>
<tr><td>Innodb_os_log_written(kb/s):</td><td align=\"right\">$sec_Innodb_os_log_written </td></tr>
</table><p /><hr />
	";
	print MYAWR_REPORT $html_line;	

my($key_buffer_read_hits,$key_buffer_write_hits,$Innodb_buffer_read_hits,$Query_cache_hits,$Thread_cache_hits);

if (($end_Key_read_requests-$start_Key_read_requests) >0) {
	$key_buffer_read_hits = int((1- ($end_Key_reads-$start_Key_reads)/($end_Key_read_requests-$start_Key_read_requests) ) * 10000 )/100;
}else{
	$key_buffer_read_hits = 0;
}

if(($end_Key_write_requests-$start_Key_write_requests) >0){
	$key_buffer_write_hits = int((1- ($end_Key_writes-$start_Key_writes)/($end_Key_write_requests-$start_Key_write_requests) ) * 10000)/100;
}else{
	$key_buffer_write_hits = 0
}

if(($end_Innodb_buffer_pool_read_requests - $start_Innodb_buffer_pool_read_requests) >0){
	$Innodb_buffer_read_hits = int((1 - ($end_Innodb_buffer_pool_reads - $start_Innodb_buffer_pool_reads) / ($end_Innodb_buffer_pool_read_requests - $start_Innodb_buffer_pool_read_requests)) * 10000)/100;
}else{
	$Innodb_buffer_read_hits = 0;
}

if(($end_Qcache_hits - $start_Qcache_hits + $end_Qcache_inserts - $start_Qcache_inserts )>0){
	$Query_cache_hits = int((($end_Qcache_hits - $start_Qcache_hits) / ($end_Qcache_hits - $start_Qcache_hits + $end_Qcache_inserts - $start_Qcache_inserts )) * 10000)/100;
}else{
	$Query_cache_hits =0;
}

if(($end_Connections - $start_Connections) >0){
	$Thread_cache_hits = int((1 - ($end_Threads_created-$start_Threads_created )/ ($end_Connections - $start_Connections) ) * 10000)/100;
}else{
	$Thread_cache_hits = 0;
}

	$html_line =
	"
<p /><h3>Some Key Hits</h3><p />
<table border=\"1\" width=\"600\">
<tr><th></th><th>Percentage</th></tr>
<tr><td>key_buffer_read_hits %:</td><td align=\"right\">$key_buffer_read_hits</td></tr>
<tr><td>key_buffer_write_hits %:</td><td align=\"right\">$key_buffer_write_hits</td></tr>
<tr><td>Innodb_buffer_read_hits %:</td><td align=\"right\">$Innodb_buffer_read_hits</td></tr>
<tr><td>Query_cache_hits %:</td><td align=\"right\">$Query_cache_hits</td></tr>
<tr><td>Thread_cache_hits %:</td><td align=\"right\">$Thread_cache_hits</td></tr>
</table><p /><p /><hr/>		
	";	
	
	print MYAWR_REPORT $html_line;	
    
  
    print MYAWR_REPORT "<p /><h3>Top 10 Timed Events</h3><p /><table border=\"1\" width=\"600\" > <tr><th>event_name</th><th>wait time(picsecond)</th><th>wait count</th></tr>";

		$sth = $dbh->prepare("select  b.EVENT_NAME ,b.SUM_TIMER_WAIT-a.SUM_TIMER_WAIT wait_time, b.COUNT_STAR-a.COUNT_STAR wait_count from (select * from myawr_snapshot_events_waits_summary_global_by_event_name where host_id=$tid and snap_id=$start_snap_id  and snap_time=\"$start_snap_time\") a, (select * from myawr_snapshot_events_waits_summary_global_by_event_name where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\") b WHERE a.EVENT_NAME=b.EVENT_NAME order by b.SUM_TIMER_WAIT-a.SUM_TIMER_WAIT desc limit 10");
		$sth->execute();
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td></tr>";  
	          print MYAWR_REPORT "\n";
		  }
		  
    print MYAWR_REPORT "</table>";

    print MYAWR_REPORT "<p /><h3>Top 10 read file Events</h3><p />   <table border=\"1\" width=\"600\" > <tr><th>event_name</th><th>read bytes</th><th>read count</th></tr>";

		$sth = $dbh->prepare("select  b.EVENT_NAME ,b.SUM_NUMBER_OF_BYTES_READ-a.SUM_NUMBER_OF_BYTES_READ file_read, b.COUNT_READ-a.COUNT_READ read_count from (select * from myawr_snapshot_file_summary_by_event_name where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_snapshot_file_summary_by_event_name where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.EVENT_NAME=b.EVENT_NAME order by b.SUM_NUMBER_OF_BYTES_READ-a.SUM_NUMBER_OF_BYTES_READ desc limit 10");
		$sth->execute();
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td></tr>";  
	          print MYAWR_REPORT "\n";
		  }
		  
    print MYAWR_REPORT "</table>";

			  	
    print MYAWR_REPORT "<p /><h3>Top 10 write file Events</h3><p /><table border=\"1\" width=\"600\" > <tr><th>event_name</th><th>read bytes</th><th>read count</th></tr>";

		$sth = $dbh->prepare("select  b.EVENT_NAME ,b.SUM_NUMBER_OF_BYTES_WRITE-a.SUM_NUMBER_OF_BYTES_WRITE file_write, b.COUNT_WRITE-a.COUNT_WRITE write_count from (select * from myawr_snapshot_file_summary_by_event_name where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_snapshot_file_summary_by_event_name where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.EVENT_NAME=b.EVENT_NAME order by b.SUM_NUMBER_OF_BYTES_WRITE - a.SUM_NUMBER_OF_BYTES_WRITE desc limit 10");
		$sth->execute();
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td></tr>";  
	          print MYAWR_REPORT "\n";
		}
		  
    print MYAWR_REPORT "</table><p /><hr/><p />";

   print  MYAWR_REPORT "<p /><h2>Performance Schema Stats</h2><p />";

    print MYAWR_REPORT "<p /><h3>Top IO Stat by host</h3><p />   <table border=\"1\" width=\"600\" > <tr><th>host_name</th><th>io_count</th><th>io_latency_count(ms)</th></tr>";

       $sth = $dbh->prepare("select  b.host_name ,b.io_sum-a.io_sum io_summary, round((b.io_latency-a.io_latency)/1000/1000/1000,2)  io_latency from (select * from myawr_host_summary_by_file_io where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_host_summary_by_file_io where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.host_name=b.host_name order by b.io_sum-a.io_sum desc limit 10");
       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";

       print MYAWR_REPORT "<p /><h3>Top Summary statment by host</h3><p />   <table border=\"1\" width=\"900\" > <tr><th>host</th><th>total</th><th>total_latency</th><th>max_latency</th><th>lock_latency</th><th>rows_sent</th><th>rows_examined</th><th>rows_affected</th><th>full_scans</th></tr>";

       $sth = $dbh->prepare("select  b.host_name ,b.total-a.total total, round((b.total_latency-a.total_latency)/1000/1000/1000,2)  total_latency ,round(b.max_latency/1000/1000/1000,2) max_latency, round((b.lock_latency-a.lock_latency)/1000/1000/1000,2) lock_latency, b.rows_sent-a.rows_sent ,b.rows_examined-a.rows_examined, b.rows_affected-a.rows_affected,b.full_scans-a.full_scans from (select * from myawr_host_summary_by_statement_latency  where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_host_summary_by_statement_latency  where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.host_name=b.host_name order by b.total_latency-a.total_latency desc limit 10");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td><td align=\"right\">$result[8]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";


       print MYAWR_REPORT "<p /><h3>Top IO Stat by user </h3><p />   <table border=\"1\" width=\"600\" > <tr><th>user_name</th><th>io_count</th><th>io_latency_count(ms)</th></tr>";

       $sth = $dbh->prepare("select  b.user_name ,b.io_sum-a.io_sum io_summary, round((b.io_latency-a.io_latency)/1000/1000/1000,2)  io_latency from (select * from myawr_user_summary_by_file_io where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_user_summary_by_file_io where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.user_name=b.user_name order by b.io_sum-a.io_sum desc limit 10");
       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";

       print MYAWR_REPORT "<p /><h3>Top Summary statment by user</h3><p />   <table border=\"1\" width=\"900\" > <tr><th>user</th><th>total</th><th>total_latency</th><th>max_latency</th><th>lock_latency</th><th>rows_sent</th><th>rows_examined</th><th>rows_affected</th><th>full_scans</th></tr>";

       $sth = $dbh->prepare("select  b.user_name ,b.total-a.total total, round((b.total_latency-a.total_latency)/1000/1000/1000,2)  total_latency ,round(b.max_latency/1000/1000/1000,2) max_latency, round((b.lock_latency-a.lock_latency)/1000/1000/1000,2) lock_latency, b.rows_sent-a.rows_sent ,b.rows_examined-a.rows_examined, b.rows_affected-a.rows_affected,b.full_scans-a.full_scans from (select * from myawr_user_summary_by_statement_latency  where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_user_summary_by_statement_latency  where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.user_name=b.user_name order by b.total_latency-a.total_latency desc limit 10");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td><td align=\"right\">$result[8]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";


       print MYAWR_REPORT "<p /><h3>Global Read File IO by Bytes</h3><p />   <table border=\"1\" width=\"900\" > <tr><th>file_name</th><th>count_read</th><th>total_read(KB)</th><th>avg_read(KB)</th><th>write_pct</th></tr>";

       $sth = $dbh->prepare("select  b.file ,b.count_read-a.count_read count_read, round((b.total_read-a.total_read)/1024,2)  total_read ,round(b.avg_read/1024,2) avg_read   ,b.write_pct  write_pct  from (select * from myawr_io_read_global_by_file_by_bytes  where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_io_read_global_by_file_by_bytes  where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b where  a.file=b.file   order by  total_read  desc  limit 10");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";


       print MYAWR_REPORT "<p /><h3>Global Write File IO by Bytes</h3><p />   <table border=\"1\" width=\"900\" > <tr><th>file_name</th><th>count_write</th><th>total_write(KB)</th><th>avg_write(KB)</th><th>write_pct</th></tr>";

       $sth = $dbh->prepare("select  b.file ,b.count_write-a.count_write count_write, round((b.total_write-a.total_write)/1024,2)  total_write ,round(b.avg_write/1024,2) avg_write   ,b.write_pct  write_pct  from (select * from myawr_io_write_global_by_file_by_bytes  where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (select * from myawr_io_write_global_by_file_by_bytes  where  host_id=$tid and snap_id=$end_snap_id  and snap_time=\"$end_snap_time\") b WHERE a.file=b.file order by total_write desc limit 10");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table><p /><hr/><p />";


       print MYAWR_REPORT "<p /><h3>Global File IO Latency</h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>file_name</th><th>total</th><th>total_latency(ms)</th><th>count_read</th><th>read_latency(ms)</th><th>count_write</th><th>write_latency(ms)</th><th>count_misc</th><th>misc_latency(ms)</th></tr>";

       $sth = $dbh->prepare("SELECT 
  b.file,
  b.total - a.total total,
  ROUND(
    (b.total_latency - a.total_latency) / 1000/1000/1000,
    2
  ) total_latency,
  b.count_read-a.count_read count_read,
  ROUND((b.read_latency-a.read_latency )/1000/1000/1000,2) read_latency,
    b.count_write-a.count_write count_write,
  ROUND((b.write_latency-a.write_latency )/1000/1000/1000,2) write_latency,
    b.count_misc-a.count_misc count_misc,
  ROUND((b.misc_latency-a.misc_latency )/1000/1000/1000,2) misc_latency
  
FROM
  (SELECT 
    * 
  FROM
    myawr_io_global_file_by_latency
  where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\" 
 ) a, (SELECT * FROM  myawr_io_global_file_by_latency  where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\") b WHERE a.file=b.file ORDER BY total_latency DESC LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td><td align=\"right\">$result[8]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";




       print MYAWR_REPORT "<p /><h3>Global Event IO Latency</h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>event_name</th><th>total</th><th>total_latency(ms)</th><th>avg_latency(ms)</th><th>max_latency(ms)</th><th>read_latency(ms)</th><th>write_latency(ms)</th><th>misc_latency(ms)</th><th>total_read</th><th>total_written</th></tr>";

       $sth = $dbh->prepare("SELECT 
  b.event_name,
  b.total - a.total total,
  ROUND(
    (b.total_latency - a.total_latency) / 1000/1000/1000,2
  ) total_latency,
  round(b.avg_latency/1000/1000/1000,2),
  round(b.max_latency/1000/1000/1000,2),
  ROUND((b.read_latency-a.read_latency )/1000/1000/1000,2) read_latency,
  ROUND((b.write_latency-a.write_latency )/1000/1000/1000,2) write_latency,
  ROUND((b.misc_latency-a.misc_latency )/1000/1000/1000,2) misc_latency,
  b.total_read-a.total_read  total_read,
  b.total_written-a.total_written total_written
  
FROM
  (SELECT 
    event_name,total,total_latency,avg_latency,max_latency,read_latency,write_latency,misc_latency,total_read,total_written 
  FROM
    `myawr_io_global_event_by_latency` 
   where host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a, (SELECT event_name,total,total_latency,avg_latency,max_latency,read_latency,write_latency,misc_latency,total_read,total_written FROM  myawr_io_global_event_by_latency   where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\") b WHERE a.event_name=b.event_name  LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td><td align=\"right\">$result[8]</td><td align=\"right\">$result[9]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

        print MYAWR_REPORT "</table>";


     print MYAWR_REPORT "<p /><h3>Global Event Class Wait latency  </h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>event_class</th><th>total</th><th>total_latency</th><th>min_latency</th><th>avg_latency</th><th>max_latency</th></tr>";


       $sth = $dbh->prepare("select event_class,total,total_latency,min_latency,avg_latency,max_latency
   
FROM
    `myawr_wait_classes_global_by_avg_latency` 
   where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"  LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table><p /><hr/><p />";




       print MYAWR_REPORT "<p /><h3>Global Satament Table Full Scan</h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>db</th><th>exec_count</th><th>no_idx_count</th><th>no_gidx_count</th><th>no_ind_use_pct</th><th>rows_sent</th><th>rows_exam</th><th>last_seen_time_stamp</th></tr>";

       $sth = $dbh->prepare("SELECT db,exec_count,no_index_used_count,no_good_index_used_count,no_index_used_pct,rows_sent,rows_examined,last_seen
   
FROM
    `myawr_statements_with_full_table_scans` 
   where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"  LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";


       print MYAWR_REPORT "<p /><h3>Global Satament Table Full SQL </h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>query</th><th>digest</th></tr>";

       $sth = $dbh->prepare("SELECT query,digest
   
FROM
    `myawr_statements_with_full_table_scans` 
   where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"  LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";


       print MYAWR_REPORT "<p /><h3>Global Satament TEMP Table Usage </h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>db</th><th>exec_count</th><th>total_latency(ms)</th><th>memory_tmp_tables</th><th>disk_tmp_tables</th><th>avg_tmp_tables_per_query</th><th>tmp_tables_to_disk_pct</th><th>last_seen</th></tr>";

       $sth = $dbh->prepare("SELECT db,exec_count,
   round(total_latency/1000/1000/1000,2),memory_tmp_tables,disk_tmp_tables,avg_tmp_tables_per_query,tmp_tables_to_disk_pct,last_seen
FROM
    `myawr_statements_with_temp_tables` 
   where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"  LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td align=\"right\">$result[4]</td><td align=\"right\">$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";

       print MYAWR_REPORT "<p /><h3>Global Satament TEMP Table SQL</h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>query</th><th>digest</th></tr>";

       $sth = $dbh->prepare("SELECT query,digest
   
FROM
    `myawr_statements_with_temp_tables` 
   where host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\"  LIMIT 10 ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

        print MYAWR_REPORT "</table><p /><hr/><p />";



 print MYAWR_REPORT "<p /><h3>Global Segments by Index </h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>table_schema</th><th>table_name</th><th>index_name</th><th>rows_selected</th><th>select_latency(ms)</th><th>rows_inserted</th><th>insert_latency(ms)</th><th>rows_updated</th><th>update_latency(ms)</th><th>rows_deleted</th><th>delete_latency(ms)</th></tr>";

       $sth = $dbh->prepare("SELECT 
  b.object_schema,
  b.table_name,
  b.index_name,
  b.rows_selected - a.rows_selected rows_selected,
  ROUND((b.select_latency - a.select_latency )/1000/1000/1000,2) select_latency,
  b.rows_inserted - a.rows_inserted rows_inserted,
  ROUND((b.insert_latency - a.insert_latency )/1000/1000/1000,2) insert_latency,
  b.rows_updated - a.rows_updated rows_updated,
  ROUND((b.update_latency - a.update_latency )/1000/1000/1000,2) update_latency,
  b.rows_deleted - a.rows_deleted rows_deleted,
  ROUND((b.delete_latency - a.delete_latency )/1000/1000/1000,2) delete_latency 
FROM
  (SELECT 
    object_schema,
    table_name,
    index_name,
    rows_selected,
    select_latency,
    rows_inserted,
    insert_latency,
    rows_updated,
    update_latency,
    rows_deleted,
    delete_latency 
  FROM
    `myawr_segment_global_stat` 
  WHERE object_type = 'I' 
   and host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a,
  (SELECT 
    object_schema,
    table_name,
    index_name,
    rows_selected,
    select_latency,
    rows_inserted,
    insert_latency,
    rows_updated,
    update_latency,
    rows_deleted,
    delete_latency 
  FROM
    `myawr_segment_global_stat` 
  WHERE object_type = 'I' 
   and host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\") b 
WHERE a.table_name = b.table_name 
  AND a.index_name = b.index_name 
  AND b.rows_selected - a.rows_selected > 0 
ORDER BY rows_selected DESC 
LIMIT 10  ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td>$result[2]</td><td>$result[3]</td><td>$result[4]</td><td>$result[5]</td><td>$result[6]</td><td>$result[7]</td><td>$result[8]</td><td>$result[9]</td><td>$result[10]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table>";




 print MYAWR_REPORT "<p /><h3>Global Segments by Table </h3><p />   <table border=\"1\" width=\"1100\" > <tr><th>table_schema</th><th>table_name</th><th>rows_selected</th><th>select_latency(ms)</th><th>rows_inserted</th><th>insert_latency(ms)</th><th>rows_updated</th><th>update_latency(ms)</th><th>rows_deleted</th><th>delete_latency(ms)</th></tr>";

       $sth = $dbh->prepare("SELECT 
  b.object_schema,
  b.table_name,
  b.rows_selected - a.rows_selected rows_selected,
  ROUND((b.select_latency - a.select_latency )/1000/1000/1000,2) select_latency,
  b.rows_inserted - a.rows_inserted rows_inserted,
  ROUND((b.insert_latency - a.insert_latency )/1000/1000/1000,2) insert_latency,
  b.rows_updated - a.rows_updated rows_updated,
  ROUND((b.update_latency - a.update_latency )/1000/1000/1000,2) update_latency,
  b.rows_deleted - a.rows_deleted rows_deleted,
  ROUND((b.delete_latency - a.delete_latency )/1000/1000/1000,2) delete_latency 
FROM
  (SELECT 
    object_schema,
    table_name,
    rows_selected,
    select_latency,
    rows_inserted,
    insert_latency,
    rows_updated,
    update_latency,
    rows_deleted,
    delete_latency 
  FROM
    `myawr_segment_global_stat` 
  WHERE object_type = 'T' 
   and host_id=$tid and snap_id=$start_snap_id and snap_time=\"$start_snap_time\") a,
  (SELECT 
    object_schema,
    table_name,
    rows_selected,
    select_latency,
    rows_inserted,
    insert_latency,
    rows_updated,
    update_latency,
    rows_deleted,
    delete_latency 
  FROM
    `myawr_segment_global_stat` 
  WHERE object_type = 'T' 
   and host_id=$tid and snap_id=$end_snap_id and snap_time=\"$end_snap_time\") b 
WHERE a.table_name = b.table_name 
  AND b.rows_selected - a.rows_selected > 0 
ORDER BY rows_selected DESC 
LIMIT 10  ");

       $sth->execute();
       while( my @result = $sth->fetchrow_array )      {
                print MYAWR_REPORT "<tr>   <td>$result[0]</td><td align=\"right\">$result[1]</td><td>$result[2]</td><td>$result[3]</td><td>$result[4]</td><td>$result[5]</td><td>$result[6]</td><td>$result[7]</td><td>$result[8]</td><td>$result[9]</td></tr>";
                print MYAWR_REPORT "\n";
                  }

       print MYAWR_REPORT "</table><p /><hr/><p />";

		my $rskip=($end_snap_id - $start_snap_id+1)/$rprint;
		
		$rskip=int($rskip+0.5);
		if($rskip< 1) {
			$rskip=1;
		}
		
		my $n=$start_snap_id;
		while($n < $end_snap_id){
			$sql =$sql. $n .",";
			$n= $n+ 0 +$rskip;
		}
		$sql.="$end_snap_id";
		
		
my $isfirst=1;
my $sinterval;
my $insert_diff ;
my $update_diff;
my $delete_diff;
my $select_diff;
my $read_request;
my $read;
my $innodb_rows_inserted_diff;
my $innodb_rows_updated_diff;
my $innodb_rows_deleted_diff;
my $innodb_rows_read_diff;
my $innodb_os_log_fsyncs_diff;
my $innodb_os_log_written_diff;
my $stps;
my $shits;

my($pre_snap_time,$pre_unix_s ,$pre_Innodb_rows_inserted,$pre_Innodb_rows_updated,$pre_Innodb_rows_deleted,$pre_Innodb_rows_read,$pre_Innodb_buffer_pool_read_requests,$pre_Innodb_buffer_pool_reads,$pre_Innodb_os_log_fsyncs,$pre_Innodb_os_log_written,$pre_Com_select,$pre_Com_delete,$pre_Com_insert,$pre_Com_update);

		$sth = $dbh->prepare("select a.snap_time,UNIX_TIMESTAMP(a.snap_time) unix_s ,a.Innodb_rows_inserted,a.Innodb_rows_updated,a.Innodb_rows_deleted,a.Innodb_rows_read,a.Innodb_buffer_pool_read_requests,a.Innodb_buffer_pool_reads,a.Innodb_os_log_fsyncs,a.Innodb_os_log_written, b.Com_select,b.Com_delete,b.Com_insert,b.Com_update ,b.Threads_running  from myawr_innodb_info a,myawr_mysql_info b where a.host_id=b.host_id and a.snap_id=b.snap_id and  a.host_id=$tid and  a.snap_id in ($sql) and a.snap_time between \"$start_snap_time\" and \"$end_snap_time\" ");
		$sth->execute();

	    print MYAWR_REPORT "<p /><h3>Innodb activity(1)</h3><p /><table border=\"1\" width=\"1320\"> <tr><th>Snap Time</th><th>Com_ins</th><th>Com_upd</th><th>Com_del</th><th>Com_sel</th><th>TPS</th><th>Buf_read_req</th><th>Hit%</th><th>Innodb_rows_ins</th><th>Innodb_rows_upd</th><th>Innodb_rows_del</th><th>Innodb_rows_read</th><th>Innodb_log_fsyncs</th><th>Innodb_log_wrn(k/s)</th><th>Threads_running</th></tr>";
				
		while( my @result = $sth->fetchrow_array ){
			if ($isfirst==1){
				$pre_snap_time=$result[0];
				$pre_unix_s=$result[1]; 
				$pre_Innodb_rows_inserted=$result[2];
				$pre_Innodb_rows_updated=$result[3];
				$pre_Innodb_rows_deleted=$result[4];
				$pre_Innodb_rows_read=$result[5];
				$pre_Innodb_buffer_pool_read_requests=$result[6];
				$pre_Innodb_buffer_pool_reads=$result[7];
				$pre_Innodb_os_log_fsyncs=$result[8];
				$pre_Innodb_os_log_written=$result[9];
				$pre_Com_select=$result[10];
				$pre_Com_delete=$result[11];
				$pre_Com_insert=$result[12];
				$pre_Com_update=$result[13];
				
				$isfirst=0;
		   }else {
		       $sinterval=$result[1]-$pre_unix_s;
               if ($sinterval>0){

					 $select_diff = int(($result[10]-$pre_Com_select) / $sinterval);
					 $delete_diff =int( ($result[11]-$pre_Com_delete) / $sinterval);
					 $insert_diff = int(($result[12]-$pre_Com_insert) / $sinterval);
					 $update_diff = int(($result[13]-$pre_Com_update) / $sinterval);
		             $stps=$insert_diff+$update_diff+$delete_diff;
		
					 $read_request = int(($result[6]-$pre_Innodb_buffer_pool_read_requests) / $sinterval);
					 $read         = int(($result[7]-$pre_Innodb_buffer_pool_reads) / $sinterval);
		                         
					 if ($read_request>0) {
						$shits = int(($read_request-$read)/$read_request*10000)/100;
					 }	
					
					 $innodb_rows_inserted_diff = int(($result[2]-$pre_Innodb_rows_inserted) / $sinterval);
					 $innodb_rows_updated_diff  = int(($result[3]-$pre_Innodb_rows_updated  ) / $sinterval);
					 $innodb_rows_deleted_diff  = int(($result[4]-$pre_Innodb_rows_deleted ) / $sinterval);
					 $innodb_rows_read_diff     = int(($result[5]-$pre_Innodb_rows_read) / $sinterval);
		
					 $innodb_os_log_fsyncs_diff = int(($result[8]- $pre_Innodb_os_log_fsyncs ) / $sinterval);
					 $innodb_os_log_written_diff= int(($result[9]-$pre_Innodb_os_log_written) / $sinterval/1024);
			
			         print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$insert_diff</td><td align=\"right\">$update_diff</td><td>$delete_diff</td><td>$select_diff</td><td>$stps</td><td>$read_request</td><td>$shits</td><td>$innodb_rows_inserted_diff</td><td>$innodb_rows_updated_diff</td><td>$innodb_rows_deleted_diff</td><td>$innodb_rows_read_diff</td><td>$innodb_os_log_fsyncs_diff</td><td>$innodb_os_log_written_diff</td><td>$result[14]</td></tr>";  
		    		 print MYAWR_REPORT "\n";
		       }
				$pre_snap_time=$result[0];
				$pre_unix_s=$result[1]; 
				$pre_Innodb_rows_inserted=$result[2];
				$pre_Innodb_rows_updated=$result[3];
				$pre_Innodb_rows_deleted=$result[4];
				$pre_Innodb_rows_read=$result[5];
				$pre_Innodb_buffer_pool_read_requests=$result[6];
				$pre_Innodb_buffer_pool_reads=$result[7];
				$pre_Innodb_os_log_fsyncs=$result[8];
				$pre_Innodb_os_log_written=$result[9];
				$pre_Com_select=$result[10];
				$pre_Com_delete=$result[11];
				$pre_Com_insert=$result[12];
				$pre_Com_update=$result[13];
		   		}
                
		  }
    print MYAWR_REPORT "</table><p /><p />";			
		


my $innodb_bp_pages_flushed_diff;
my $innodb_data_reads_diff  ;
my $innodb_data_writes_diff;
my $innodb_data_read_diff;
my $innodb_data_written_diff;
my $unflushed_log;
my $uncheckpointed_bytes;

my($pre_Innodb_buffer_pool_pages_data,$pre_Innodb_buffer_pool_pages_free,$pre_Innodb_buffer_pool_pages_dirty,$pre_Innodb_buffer_pool_pages_flushed,$pre_Innodb_data_reads,$pre_Innodb_data_writes,$pre_Innodb_data_read,$pre_Innodb_data_written,$pre_history_list,$pre_log_bytes_written,$pre_log_bytes_flushed,$pre_last_checkpoint,$pre_queries_inside,$pre_queries_queued,$pre_read_views);

$isfirst=1;


		$sth = $dbh->prepare("select a.snap_time,UNIX_TIMESTAMP(a.snap_time) unix_s,Innodb_buffer_pool_pages_data,Innodb_buffer_pool_pages_free,Innodb_buffer_pool_pages_dirty,Innodb_buffer_pool_pages_flushed,Innodb_data_reads,Innodb_data_writes,Innodb_data_read,Innodb_data_written,history_list,log_bytes_written,log_bytes_flushed,last_checkpoint,queries_inside,queries_queued,read_views  from myawr_innodb_info a where a.host_id=$tid and  a.snap_id in ($sql) and a.snap_time between \"$start_snap_time\" and \"$end_snap_time\" ");
		$sth->execute();

	    print MYAWR_REPORT "<p /><h3>Innodb activity(2)</h3><p /><table border=\"1\" width=\"1320\"> <tr><th>Snap Time</th><th>Indb_pdata</th><th>Indb_pfree</th><th>Indb_pdirty</th><th>Indb_pflush</th><th>Indb_dreads</th><th>Indb_dwrites</th><th>Indb_dread(k/s)</th><th>Indb_dwritten(k/s)</th><th>his_list</th><th>Inlog_uflush</th><th>Inlog_uckpt</th><th>queries_inside</th><th>queries_queued</th><th>read_views</th></tr>";				
		
		while( my @result = $sth->fetchrow_array ){
			if ($isfirst==1){
	    		$pre_snap_time=$result[0];
				$pre_unix_s=$result[1]; 
				
				$pre_Innodb_buffer_pool_pages_data=$result[2];
				$pre_Innodb_buffer_pool_pages_free=$result[3];
				$pre_Innodb_buffer_pool_pages_dirty=$result[4];
				$pre_Innodb_buffer_pool_pages_flushed=$result[5];

				$pre_Innodb_data_reads=$result[6];
				$pre_Innodb_data_writes=$result[7];
				$pre_Innodb_data_read=$result[8];
				$pre_Innodb_data_written=$result[9];
				$pre_history_list=$result[10];
				$pre_log_bytes_written=$result[11];
				$pre_log_bytes_flushed=$result[12];
				$pre_last_checkpoint=$result[13];

				$pre_queries_inside=$result[14];
				$pre_queries_queued=$result[15];
				$pre_read_views=$result[16];
				
				$isfirst=0;
		   }else {
		       $sinterval=$result[1]-$pre_unix_s;
               if ($sinterval>0){

				 $innodb_bp_pages_flushed_diff=int(($result[5]-$pre_Innodb_buffer_pool_pages_flushed)/$sinterval);
				 $innodb_data_reads_diff =int(($result[6]-$pre_Innodb_data_reads)/$sinterval) ;
				 $innodb_data_writes_diff=int(($result[7]-$pre_Innodb_data_writes)/$sinterval);
				 $innodb_data_read_diff=int(($result[8]-$pre_Innodb_data_read)/$sinterval/1024);
				 $innodb_data_written_diff=int(($result[9]-$pre_Innodb_data_written)/$sinterval/1024);
				 $unflushed_log=int(($result[11]-$result[12])/$sinterval/1024);
				 $uncheckpointed_bytes=int(($result[11]-$result[13])/$sinterval/1024);

		
			         print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[2]</td><td align=\"right\">$result[3]</td><td>$result[4]</td><td>$innodb_bp_pages_flushed_diff</td><td>$innodb_data_reads_diff</td><td>$innodb_data_writes_diff</td><td>$innodb_data_read_diff</td><td>$innodb_data_written_diff</td><td>$result[10]</td><td>$unflushed_log</td><td>$uncheckpointed_bytes</td><td>$result[14]</td><td>$result[15]</td><td>$result[16]</td></tr>";  
		    		 print MYAWR_REPORT "\n";

		       }

	    		$pre_snap_time=$result[0];
				$pre_unix_s=$result[1]; 
				
				$pre_Innodb_buffer_pool_pages_data=$result[2];
				$pre_Innodb_buffer_pool_pages_free=$result[3];
				$pre_Innodb_buffer_pool_pages_dirty=$result[4];
				$pre_Innodb_buffer_pool_pages_flushed=$result[5];

				$pre_Innodb_data_reads=$result[6];
				$pre_Innodb_data_writes=$result[7];
				$pre_Innodb_data_read=$result[8];
				$pre_Innodb_data_written=$result[9];
				$pre_history_list=$result[10];
				$pre_log_bytes_written=$result[11];
				$pre_log_bytes_flushed=$result[12];
				$pre_last_checkpoint=$result[13];

				$pre_queries_inside=$result[14];
				$pre_queries_queued=$result[15];
				$pre_read_views=$result[16];

		   		}
                
		  }
    print MYAWR_REPORT "</table><p /><hr/><p />";		



		$sth = $dbh->prepare(" select a.snap_id,a.snap_time,a.cpu_user,a.cpu_system,a.cpu_idle,a.cpu_iowait,b.load1,b.load5,d.Threads_connected,d.Threads_running,(select count(1) from myawr_innodb_lock_waits e where a.host_id=e.host_id and a.snap_id=e.snap_id ) lock_waits from myawr_cpu_info a,myawr_load_info b,(select host_id,snap_id,snap_time from myawr_engine_innodb_status where host_id=$tid and  snap_id BETWEEN $start_snap_id and $end_snap_id and snap_time between \"$start_snap_time\" and \"$end_snap_time\"  group by host_id,snap_id,snap_time) c,myawr_mysql_info d where a.host_id=b.host_id and a.host_id=c.host_id and a.host_id=d.host_id and a.snap_id=b.snap_id and a.snap_id=c.snap_id and a.snap_id=d.snap_id ");
		$sth->execute();

	print MYAWR_REPORT "<p /><h3>MySql peak point Info(you can use myawrsrpt to generate a snap report)</h3><p /><table border=\"1\"  > <tr><th>Snap ID</th><th>Snap Time</th><th>user</th><th>system</th><th>idle</th><th>iowait</th> <th>load1</th><th>load5</th>  <th>Threads_connected</th><th>Threads_running</th><th>lock_waits</th> </tr>";
				
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td>$result[3]</td><td>$result[4]</td><td>$result[5]</td><td align=\"right\">$result[6]</td><td align=\"right\">$result[7]</td><td>$result[8]</td><td>$result[9]</td><td>$result[10]</td></tr>";  
	          print MYAWR_REPORT "\n";
		  }
    print MYAWR_REPORT "</table><p /><hr/><p />";	
 	print MYAWR_REPORT "\n";   
 			
		
		$sth = $dbh->prepare("SELECT a.snap_time,a.load1,a.load5,a.load15 from myawr_load_info a WHERE a.host_id=$tid and a.snap_id in ($sql) and a.snap_time between \"$start_snap_time\" and \"$end_snap_time\" ");
		$sth->execute();

	print MYAWR_REPORT "<p /><h3>OS Load Info</h3><p /><table border=\"1\" width=\"600\" > <tr><th>Snap Time</th><th>load1</th><th>load5</th><th>load15</th></tr>";
				
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td>$result[3]</td></tr>";  
	    	  print MYAWR_REPORT "\n";
		  }
    print MYAWR_REPORT "</table><p />";		
    
    
		$sth = $dbh->prepare("SELECT a.snap_time,a.cpu_user,a.cpu_system,a.cpu_idle,a.cpu_iowait from myawr_cpu_info a  WHERE  a.host_id=$tid and  a.snap_id in ($sql) and a.snap_time between \"$start_snap_time\" and \"$end_snap_time\" ");
		$sth->execute();

	print MYAWR_REPORT "<p /><h3>OS CPU Info</h3><p /><table border=\"1\" width=\"600\" > <tr><th>Snap Time</th><th>user</th><th>system</th><th>idle</th><th>iowait</th></tr>";
				
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td>$result[3]</td><td>$result[4]</td></tr>";  
	          print MYAWR_REPORT "\n";
		  }
    print MYAWR_REPORT "</table><p />";	
 	print MYAWR_REPORT "\n";   

		$sth = $dbh->prepare("SELECT a.snap_time,a.rd_ios_s,a.wr_ios_s,a.rkbs,a.wkbs,a.queue,a.svc_t,a.busy from myawr_io_info a WHERE  a.host_id=$tid and  a.snap_id in ($sql) and a.snap_time between \"$start_snap_time\" and \"$end_snap_time\" ");
		$sth->execute();

	print MYAWR_REPORT "<p /><h3>OS IO Info</h3><p /><table border=\"1\" width=\"600\" > <tr><th>Snap Time</th><th>rd_ios_s</th><th>wr_ios_s</th><th>rkbs</th><th>wkbs</th><th>queue</th><th>svc_t</th><th>busy</th></tr>";
				
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td>$result[3]</td><td>$result[4]</td><td>$result[5]</td><td>$result[6]</td><td>$result[7]</td></tr>";  
	          print MYAWR_REPORT "\n";
		  }
    print MYAWR_REPORT "</table><p />";	
    
    
 		$sth = $dbh->prepare("SELECT a.snap_time,a.swap_in,a.swap_out,a.net_recv,a.net_send,a.file_system,a.total_mb,a.used_mb,a.used_pct,a.mount_point from myawr_swap_net_disk_info a WHERE a.host_id=$tid and  a.snap_id in ($sql) and a.snap_time between \"$start_snap_time\" and \"$end_snap_time\" ");
		$sth->execute();

	print MYAWR_REPORT "<p /><h3>OS Other Info</h3><p /><table border=\"1\" width=\"900\" > <tr><th>Snap Time</th><th>swap_in</th><th>swap_out</th><th>net_recv</th><th>net_send</th><th>file_system</th><th>total_mb</th><th>used_mb</th><th>used_pct</th><th>mount_point</th></tr>";
				
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td>$result[0]</td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td>$result[3]</td><td>$result[4]</td><td>$result[5]</td><td>$result[6]</td><td>$result[7]</td><td>$result[8]</td><td>$result[9]</td></tr>";  
	          print MYAWR_REPORT "\n";
		  }
    print MYAWR_REPORT "</table><p /><hr/>";	   


my $tmp_table;

 		$sth = $dbh->prepare("select a.checksum,a.db_max,a.ts_min,a.ts_max,a.ts_cnt,a.Query_time_sum,a.Query_time_pct_95,a.Lock_time_sum,a.Lock_time_pct_95,a.Rows_sent_sum,a.Rows_sent_pct_95,a.sample from dbmon.global_query_review_history  a where a.hostid_max=$tid  and dbport_max=$tport and ( (a.ts_min >= \"$start_snap_time\" and a.ts_min <= \"$end_snap_time\" and a.ts_max between  \"$start_snap_time\" and   date_add(\"$end_snap_time\", interval +1 day) ) or  (a.ts_max >= \"$start_snap_time\" and a.ts_max <= \"$end_snap_time\") ) order by a.Query_time_sum desc limit 20");
		$sth->execute();
		
	print MYAWR_REPORT "<p /><h3>TOP SLOW SQL</h3><p /><table border=\"1\" width=\"100%\" > <tr><th>checksum</th><th>db name</th><th>ts_min</th><th>ts_max</th><th>ts_cnt</th><th>Query_time_sum</th><th>Query_time_pct_95</th><th>Lock_time_sum</th><th>Lock_time_pct_95</th><th>Rows_sent_sum</th><th>Rows_sent_pct_95</th><th>sample</th></tr>";
				
		while( my @result = $sth->fetchrow_array )	{
			  print MYAWR_REPORT "<tr><td><a href=\"#$result[0]\">$result[0]</a></td><td align=\"right\">$result[1]</td><td align=\"right\">$result[2]</td><td>$result[3]</td><td>$result[4]</td><td>$result[5]</td><td>$result[6]</td><td>$result[7]</td><td>$result[8]</td><td>$result[9]</td><td>$result[10]</td><td>" . substr($result[11],0,20). "... </td></tr>";  	    
		      print MYAWR_REPORT "\n";
		      
		      $tmp_table .="<tr><td><a  name=\"$result[0]\"></a>$result[0]</td><td>$result[11]<td></tr>\n";
		} 
    print MYAWR_REPORT "</table><p /><p /><p />";           

	print MYAWR_REPORT "<p /><h3>TOP SQL DETAIL</h3><p /><table border=\"1\" width=\"100%\" > <tr><th>checksum</th><th>sql detail</th></tr>";
    print MYAWR_REPORT $tmp_table;
     print MYAWR_REPORT "</table><p /><p /><p />";   

	print MYAWR_REPORT $myawrrpt_foot;
	close MYAWR_REPORT or die "can't close!";	


    print  "\n";
    print "Generate the mysql report Successfully.\n";
    
    $sth->finish;
	$dbh->disconnect();
}
