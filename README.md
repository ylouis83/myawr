##Welcome to the myawr world !

###history of myawr

####Present: myawrv3

base on myawr_v2

myawr_v3 add sys schema information

(statment statistics/index&table stat/IO latency/file&table IO stat and so on)

including performance schema and information schema

so you need open performance schema on your mysql database

myawr_v3 now support mysql 5.6 GA and will continue support mysql feature version

before install myawr_v3 you need run sys_schema to create formatted views for data collecting.

-----------------------------------------------------------------------------------------------------

####2014/08: myawrv2

myawr_v2 was modified by louis liu base on myawr

myawr was mysql awr report referenced by oracle AWR and was wrote by perl language. myawr need slow_log and Percona tools .

myawr_v2 add :

1 os information module.

2 multi instance support (extend table by db_port)

3 modified some bugs (mistake value)

4 add different statistics views

Myawr is a tool for collecting and analyzing performance data for MySQL database (including os info ,mysql status info and Slow Query Log all of details). The idea comes from Oracle awr. Myawr periodic collect data and save to the database as snapshots. Myawr was designed as CS architecture.Myawr depends on (but not necessary) performance schema of MySQL database.

Myawr consists of three parts: myawr.pl--------a perl script for collecting mysql performance data myawrrpt.pl-----a perl script for analyzing mysql performance data myawrsrpt.pl-----a perl script for analyzing mysql peak time data

Myawr relies on the Percona Toolkit to do the slow query log collection. Specifically you can run pt-query-digest. To parse your slow logs and insert them into your server database for reporting and analyzing.

You need to init myawr by yourself :

run myawr.sql to create tables

insert agent client inforamtion :

eg :

####INSERT INTO myawr_host(id,host_name,ip_addr,port,db_role,version, running_thread_threshold,times_per_hour) VALUES (6, 'db2.11', '192.168.2.11', 3306, 'master', '5.5.27',10000,0);

id should be unique identify to every instance ( for multi instance you should add id=1 and port=x for instance 1 and id=2 and port=y for instance 2)

Then you can run crontab job to collect data as you want

#### * * * * sh /usr/local/dbadmin/monitor/myawr21_3309.sh > /tmp/myawr21_3309.log 2>&1

####/usr/bin/perl /usr/local/dbadmin/monitor/mysqlawr.pl -u dbadmin -p xxxxx -lh 10.128.6.21 -P 3309 -tu dbmon -tp dbmon -TP 3310 -th 10.128.6.21 -n bond0 -d sdb -I 1


After collecting data you can run myawrrpt1 scripts to format date and display them on the website.

eg:

####perl mysqlawrrpt1.pl -u dbmon -p dbmon -T 3309 -lh 10.128.6.21 -P 3310 -I 1

..
..

Enter value for report_name:myawr_v3.html

Using the report name :myawr_v3.html

Generating the mysql report for this analysis ... Generate the mysql report Successfully.
