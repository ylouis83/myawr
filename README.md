Welcome to the myawr world !

history of myawr 

Present:

myawrv3

base on myawr_v2

myawr_v3 add sys schema information

(statment statistics/index&table stat/IO latency/file&table IO stat and so on)

including performance schema and information schema

so you need open performance schema on you mysql database

myawr_v3 now support mysql 5.6 GA and will continue support mysql feature version 

before install myawr_v3 you need run sys_schema to create formatted views for data collecting.

------------------------------------------------------------------------------------------------------------

2014/08:

myawrv2

myawr_v2 was modified by louis liu base on myawr

myawr was mysql awr report referenced by oracle AWR and was wrote by perl language. myawr need slow_log and Percona tools .

myawr_v2 add :

1 os information module.

2 multi instance support (extend table by db_port)

3 modified some bugs (mistake value)

4 add different statistics views



Myawr is a tool for collecting and analyzing performance data for MySQL database (including os info ,mysql status info and Slow Query Log  all of details). 
The idea comes from Oracle awr. Myawr periodic collect data and save to the database as snapshots.
Myawr was designed as CS architecture.Myawr depends on (but not necessary) performance schema of MySQL database.

Myawr consists of three parts:
myawr.pl--------a perl script for collecting mysql performance data
myawrrpt.pl-----a perl script for analyzing mysql performance data
myawrsrpt.pl-----a perl script for analyzing mysql peak time data

Myawr relies on the Percona Toolkit to do the slow query log collection.
Specifically you can run pt-query-digest. To parse your slow logs and insert them into your server database for reporting and analyzing. 

You need to init myawr by yourself :

1. run myawr.sql to create tables

2. insert agent client inforamtion :

eg :

INSERT INTO `myawr_host`(id,host_name,ip_addr,port,db_role,version, running_thread_threshold,times_per_hour) VALUES (6, 'db2.11', '192.168.2.11', 3306, 'master', '5.5.27',10000,0);

id should be unique identify to every instance ( for multi instance you should add id=1 and port=x for instance 1 and id=2 and port=y for instance 2)

Then you can run crontab job to collect data as you want 

* * * * * sh  /usr/local/dbadmin/monitor/myawr21_3309.sh  > /tmp/myawr21_3309.log 2>&1


/usr/bin/perl /usr/local/dbadmin/monitor/mysqlawr.pl -u dbadmin  -p xxxxx  -lh 10.128.6.21 -P 3309  -tu dbmon -tp dbmon -TP 3310 -th 10.128.6.21 -n bond0 -d sdb -I 1

After collecting data  you can run myawrrpt1 scripts to format date and display them on the website.

eg:

perl  mysqlawrrpt1.pl   -u dbmon   -p dbmon  -T 3309  -lh 10.128.6.21 -P 3310 -I 1
===================================================
|       Welcome to use the myawrrpt tool !   
|             Date: 2014-12-01
|
|      Hostname is: a1-dba-tech01.hz 
|       Ip addr is: 10.128.6.21 
|          Port is: 3309 
|       Db role is: master 
|Server version is: 5.6.17
|        Uptime is: 0y 5m 24d 2h 59mi 6s
|
|   Min snap_id is: 1 
| Min snap_time is: 2014-08-18 17:59:46 
|   Max snap_id is: 145025 
| Max snap_time is: 2014-12-01 17:47:01 
| snap interval is: 59s
===================================================

Listing the last 2 days Snapshots

snap_id:  142192      snap_time : 2014-11-29 18:34:01 
snap_id:  142240      snap_time : 2014-11-29 19:22:01 
snap_id:  142288      snap_time : 2014-11-29 20:10:01 
snap_id:  142336      snap_time : 2014-11-29 20:58:01 
snap_id:  142384      snap_time : 2014-11-29 21:46:01 
snap_id:  142432      snap_time : 2014-11-29 22:34:01 
snap_id:  142480      snap_time : 2014-11-29 23:22:01 
snap_id:  142528      snap_time : 2014-11-30 00:10:01 
snap_id:  142576      snap_time : 2014-11-30 00:58:02 
snap_id:  142624      snap_time : 2014-11-30 01:46:02 
snap_id:  142672      snap_time : 2014-11-30 02:34:01 
snap_id:  142720      snap_time : 2014-11-30 03:22:01 
snap_id:  142768      snap_time : 2014-11-30 04:10:01 
snap_id:  142816      snap_time : 2014-11-30 04:58:01 
snap_id:  142864      snap_time : 2014-11-30 05:46:01 
snap_id:  142912      snap_time : 2014-11-30 06:34:01 
snap_id:  142960      snap_time : 2014-11-30 07:22:01 
snap_id:  143008      snap_time : 2014-11-30 08:10:02 
snap_id:  143056      snap_time : 2014-11-30 08:58:01 
snap_id:  143104      snap_time : 2014-11-30 09:46:02 
snap_id:  143152      snap_time : 2014-11-30 10:34:01 
snap_id:  143200      snap_time : 2014-11-30 11:22:02 
snap_id:  143248      snap_time : 2014-11-30 12:10:01 
snap_id:  143296      snap_time : 2014-11-30 12:58:02 
snap_id:  143344      snap_time : 2014-11-30 13:46:01 
snap_id:  143392      snap_time : 2014-11-30 14:34:01 
snap_id:  143440      snap_time : 2014-11-30 15:22:02 
snap_id:  143488      snap_time : 2014-11-30 16:10:02 
snap_id:  143536      snap_time : 2014-11-30 16:58:01 
snap_id:  143584      snap_time : 2014-11-30 17:46:01 
snap_id:  143632      snap_time : 2014-11-30 18:34:01 
snap_id:  143680      snap_time : 2014-11-30 19:22:02 
snap_id:  143728      snap_time : 2014-11-30 20:10:01 
snap_id:  143776      snap_time : 2014-11-30 20:58:01 
snap_id:  143824      snap_time : 2014-11-30 21:46:01 
snap_id:  143872      snap_time : 2014-11-30 22:34:01 
snap_id:  143920      snap_time : 2014-11-30 23:22:01 
snap_id:  143968      snap_time : 2014-12-01 00:10:01 
snap_id:  144016      snap_time : 2014-12-01 00:58:01 
snap_id:  144064      snap_time : 2014-12-01 01:46:02 
snap_id:  144112      snap_time : 2014-12-01 02:34:01 
snap_id:  144160      snap_time : 2014-12-01 03:22:01 
snap_id:  144208      snap_time : 2014-12-01 04:10:02 
snap_id:  144256      snap_time : 2014-12-01 04:58:02 
snap_id:  144304      snap_time : 2014-12-01 05:46:01 
snap_id:  144352      snap_time : 2014-12-01 06:34:01 
snap_id:  144400      snap_time : 2014-12-01 07:22:02 
snap_id:  144448      snap_time : 2014-12-01 08:10:02 
snap_id:  144496      snap_time : 2014-12-01 08:58:01 
snap_id:  144544      snap_time : 2014-12-01 09:46:01 
snap_id:  144592      snap_time : 2014-12-01 10:34:02 
snap_id:  144640      snap_time : 2014-12-01 11:22:02 
snap_id:  144688      snap_time : 2014-12-01 12:10:01 
snap_id:  144736      snap_time : 2014-12-01 12:58:02 
snap_id:  144784      snap_time : 2014-12-01 13:46:01 
snap_id:  144832      snap_time : 2014-12-01 14:34:02 
snap_id:  144880      snap_time : 2014-12-01 15:22:01 
snap_id:  144928      snap_time : 2014-12-01 16:10:01 
snap_id:  144976      snap_time : 2014-12-01 16:58:01 
snap_id:  145024      snap_time : 2014-12-01 17:46:02 
snap_id:  145025      snap_time : 2014-12-01 17:47:01 

Pls select Start and End Snapshot Id

Enter value for start_snap:144976
Start Snapshot Id Is:144976

Enter value for end_snap:145025
End  Snapshot Id Is:145025

Set the Report Name


Enter value for report_name:myawr_v3.html

Using the report name :myawr_v3.html

Generating the mysql report for this analysis ...
Generate the mysql report Successfully.


