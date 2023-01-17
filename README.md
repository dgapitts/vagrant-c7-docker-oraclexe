# vagrant-c7-docker-oraclexe




## Additional steps for rlwrap setup plus a few other more standard packages

Using the default (oracle) user with the docker container


```
bash-4.2$ id
uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54330(racdba)
bash-4.2$ hostname
6a6dea0fd6f5
```

install extra packages

```
su - root -c "yum install -y oracle-epel-release-el7"
su - root -c "yum install -y rlwrap less vi"
```

and
```
echo "alias sql+='rlwrap sqlplus / as sysdba'" >> .bash_profile
. .bash_profile
sql+
```

### Custom pfile - 500M SGA and 200M PGA (1G VM)


There is a pfile in the parent project

```
~/projects/vagrant-c7-docker-oraclexe $ cat pfile
*.audit_file_dest='/opt/oracle/admin/XE/adump'
*.audit_trail='db'
*.compatible='21.0.0'
*.control_files='/opt/oracle/oradata/XE/control01.ctl'
*.db_block_size=8192
*.db_name='XE'
*.diagnostic_dest='/opt/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=XEXDB)'
*.enable_pluggable_database=true
*.local_listener=''
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.pga_aggregate_target=200m
*.processes=70
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=500m
*.undo_tablespace='UNDOTBS1'
```

I'm not yet sure how to load this into the docker container, for now we can use simple cut-and-paste for a short text file
```
cat > /tmp/pfile <<'_EOF'
*.audit_file_dest='/opt/oracle/admin/XE/adump'
*.audit_trail='db'
*.compatible='21.0.0'
*.control_files='/opt/oracle/oradata/XE/control01.ctl'
*.db_block_size=8192
*.db_name='XE'
*.diagnostic_dest='/opt/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=XEXDB)'
*.enable_pluggable_database=true
*.local_listener=''
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.pga_aggregate_target=200m
*.processes=70
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=500m
*.undo_tablespace='UNDOTBS1'
_EOF
```

then 

```
sql+
startup pfile='/tmp/pfile'
```






### Setup simple test - one million row table

```
set timing on
create table t1m (id integer, f1 varchar2(100));
-- insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 1000000;
insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 500000;
insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 500000;
set autotrace traceonly
select * from t1m;
select * from t1m;
```
NB I broke this 1million row insert into 2 lots of 500K to avoid ORA-30009 (as I'm running with only 200G of PGA)

```
insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 1000000
            *
ERROR at line 1:
ORA-30009: Not enough memory for CONNECT BY operation
```

Some sample results for the selects - 75K logical reads in 2.9 seconds 


```
Elapsed: 00:00:02.91

Execution Plan
----------------------------------------------------------
Plan hash value: 2909280484

--------------------------------------------------------------------------
| Id  | Operation	  | Name | Rows  | Bytes | Cost (%CPU)| Time	 |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |	 |   889K|    55M|  2638   (1)| 00:00:01 |
|   1 |  TABLE ACCESS FULL| T1M  |   889K|    55M|  2638   (1)| 00:00:01 |
--------------------------------------------------------------------------

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
	  8  recursive calls
	  0  db block gets
      75732  consistent gets
	  0  physical reads
	  0  redo size
   83503582  bytes sent via SQL*Net to client
     733378  bytes received via SQL*Net from client
      66668  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
    1000000  rows processed
```

which is impressive this was on a tiny 1G
```

bash-4.2$ free -m
              total        used        free      shared  buff/cache   available
Mem:            991         337          66         280         587         231
Swap:          1535         402        1133
```

and *single* CPU VM 

```
bash-4.2$ cat /proc/cpuinfo
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 70
model name	: Intel(R) Core(TM) i7-4770HQ CPU @ 2.20GHz
stepping	: 1
cpu MHz		: 2194.918
cache size	: 6144 KB
physical id	: 0
siblings	: 1
core id		: 0
cpu cores	: 1
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc pni pclmulqdq monitor ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm fsgsbase avx2 invpcid
bogomips	: 4389.83
clflush size	: 64
cache_alignment	: 64
address sizes	: 39 bits physical, 48 bits virtual
power management:
```


### docker commit - first attempt at saving state

Unfortunately I keep having to repeat these steps

```
su - root -c "yum install -y oracle-epel-release-el7"
su - root -c "yum install -y rlwrap less vi"
echo "alias sql+='rlwrap sqlplus / as sysdba'" >> .bash_profile
. .bash_profile
cat > /tmp/pfile <<'_EOF'
*.audit_file_dest='/opt/oracle/admin/XE/adump'
*.audit_trail='db'
*.compatible='21.0.0'
*.control_files='/opt/oracle/oradata/XE/control01.ctl'
*.db_block_size=8192
*.db_name='XE'
*.diagnostic_dest='/opt/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=XEXDB)'
*.enable_pluggable_database=true
*.local_listener=''
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.pga_aggregate_target=200m
*.processes=70
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=500m
*.undo_tablespace='UNDOTBS1'
_EOF
sql+
```

as oracle

```
set time on
set timing on
startup pfile=/tmp/pfile

create table t1m (id integer, f1 varchar2(100));
-- insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 1000000;
insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 500000;
insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 500000;
set autotrace traceonly
select * from t1m;
select * from t1m;
```


then in a parallel session

```
~/projects/vagrant-c7-docker-oraclexe $ vagrant ssh
Last login: Sun Jan 15 08:24:40 2023 from 10.0.2.2
-bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
[vagrant@c7-master ~]$ sudo -i
[root@c7-master ~]# docker ps
CONTAINER ID   IMAGE          COMMAND       CREATED          STATUS                    PORTS     NAMES
0ea561fcfc99   c273dde6b184   "/bin/bash"   18 minutes ago   Up 18 minutes (healthy)             gallant_borg
[root@c7-master ~]# docker images
REPOSITORY                                       TAG       IMAGE ID       CREATED        SIZE
container-registry.oracle.com/database/express   latest    c273dde6b184   3 months ago   11.2GB
[root@c7-master ~]# docker commit 0ea561fcfc99 container-registry.oracle.com/database/express:dgapitts_001
[root@c7-master ~]# docker images
REPOSITORY                                       TAG            IMAGE ID       CREATED          SIZE
container-registry.oracle.com/database/express   dgapitts_001   cacafb1a0236   16 seconds ago   16.5GB
container-registry.oracle.com/database/express   latest         c273dde6b184   3 months ago     11.2GB
```

now back in the first session lets try disconnecting from the original image and reconnecting to the new

```
Statistics
----------------------------------------------------------
	  0  recursive calls
	  0  db block gets
     113520  consistent gets
      14562  physical reads
	  0  redo size
  125255033  bytes sent via SQL*Net to client
    1100041  bytes received via SQL*Net from client
     100001  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
    1500000  rows processed

08:43:23 SQL> exit
Disconnected from Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0
bash-4.2$ exit
exit
[root@c7-master ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@c7-master ~]# docker images
REPOSITORY                                       TAG            IMAGE ID       CREATED         SIZE
container-registry.oracle.com/database/express   dgapitts_001   cacafb1a0236   3 minutes ago   16.5GB
container-registry.oracle.com/database/express   latest         c273dde6b184   3 months ago    11.2GB
[root@c7-master ~]# docker run -it cacafb1a0236  /bin/bash
bash-4.2$ id
uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54330(racdba)
bash-4.2$ sql+
bash: sql+: command not found
bash-4.2$ . .bash_profile
bash-4.2$ sql+

SQL*Plus: Release 21.0.0.0.0 - Production on Sun Jan 15 08:56:54 2023
Version 21.3.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.

Connected to an idle instance.

SQL> startup pfile=/tmp/pfile
ORACLE instance started.

Total System Global Area  524284200 bytes
Fixed Size		    9687336 bytes
Variable Size		  163577856 bytes
Database Buffers	  348127232 bytes
Redo Buffers		    2891776 bytes
Database mounted.
ORA-01114: IO error writing block to file 1 (block # 1)
ORA-01110: data file 1: '/opt/oracle/oradata/XE/system01.dbf'
ORA-27091: unable to queue I/O
ORA-27041: unable to open file
Linux-x86_64 Error: 28: No space left on device
Additional information: 3
```


### Docker image cleanup and side issue with image is being used

```
[root@c7-master ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@c7-master ~]# docker images
REPOSITORY                                       TAG            IMAGE ID       CREATED        SIZE
container-registry.oracle.com/database/express   dgapitts_001   cacafb1a0236   18 hours ago   16.5GB
container-registry.oracle.com/database/express   latest         c273dde6b184   3 months ago   11.2GB
[root@c7-master ~]# docker image rm cacafb1a0236
Error response from daemon: conflict: unable to delete cacafb1a0236 (must be forced) - image is being used by stopped container c67675064c88
```


and with [force option as per stackoverflow](https://stackoverflow.com/questions/51188657/image-is-being-used-by-stopped-container)
```
[root@c7-master ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@c7-master ~]# docker image rm -f cacafb1a0236
Untagged: container-registry.oracle.com/database/express:dgapitts_001
Deleted: sha256:cacafb1a02360ad8fb8254fdbfce83de64a0b7e7e71dbac1e8e5ec5b22e835c1
```


### Space problems - 37G in /var/lib/docker/overlay2

```
[root@c7-master overlay2]# pwd
/var/lib/docker/overlay2
[root@c7-master overlay2]# du -hs .
37G	.
[root@c7-master overlay2]# du -hs *
12K	03c0b385046e5ada7f8b95060d8fcec63f921bf64138ecd3a9c03e9b3b16b2d2
8.0K	03c0b385046e5ada7f8b95060d8fcec63f921bf64138ecd3a9c03e9b3b16b2d2-init
141M	2d432113eda2fb720467f076b20fc8962ed17afa05f72f32fab147ad043cf0ed
8.0K	2d53c9e50b418ccf7edfed88a7299bae5e2d8b872b35d79d1bc1092005ac8008
64K	2ee5dab773f746dbaf161f223856e581a142a9ed9822048c1bca7dba26972834
42M	44133c2933447ede5d55ca2d5a54938fd777ee9b78cc0a366019a3d6d75f33a7
8.0K	44133c2933447ede5d55ca2d5a54938fd777ee9b78cc0a366019a3d6d75f33a7-init
5.0G	4f233d396e47f46e0c9879fe4928ee2eab116602f49e945b9d5e32e5a6460d45
6.1G	601ee36b09fca9a8a6598e0e9da024cb46af380795f427e78e91b6d8822cdc0a
5.3G	65c75f3ea5e5ee6ca615b982b831e034bc3a9ec5114fb526763dbc0f02a84b3c
8.0K	65c75f3ea5e5ee6ca615b982b831e034bc3a9ec5114fb526763dbc0f02a84b3c-init
20K	7231d72a518a0facb5f2016e59a0df4f0aacbb6c7558cf3847d3f77c2a8d7407
8.0K	7231d72a518a0facb5f2016e59a0df4f0aacbb6c7558cf3847d3f77c2a8d7407-init
5.1G	75dfe48bcf3ea4491723784ad17c4aad8314d017935cc9d83c3f4c33ec2dbf4b
8.0K	75dfe48bcf3ea4491723784ad17c4aad8314d017935cc9d83c3f4c33ec2dbf4b-init
5.2G	8c32bca1748ce0925e49850df02b5ff80033046ada6d3fb3528710c15c2295c8
8.0K	8c32bca1748ce0925e49850df02b5ff80033046ada6d3fb3528710c15c2295c8-init
5.0G	b0e159757eedba03b407ac539943e3bc42339de9f3b27cde8c487e4d333817e9
8.0K	b0e159757eedba03b407ac539943e3bc42339de9f3b27cde8c487e4d333817e9-init
0	backingFsBlockDev
4.4G	ed400e55c4bd099739b50b8c8ed0a6b0138bcb4235730faf15954a89094c4b90
292M	ff4e8b0a9fa708a40c82e937f7ff78478d29f514c124c4c327b13e3bf17fccf7
8.0K	ff4e8b0a9fa708a40c82e937f7ff78478d29f514c124c4c327b13e3bf17fccf7-init
4.0K	l
[root@c7-master overlay2]#
```


### Rebuild project - destroy with --force option

```
~/projects/vagrant-c7-docker-oraclexe $ vagrant destroy --force
==> vagrant: A new version of Vagrant is available: 2.3.4 (installed version: 2.2.19)!
==> vagrant: To upgrade visit: https://www.vagrantup.com/downloads.html

==> master1: Forcing shutdown of VM...
==> master1: Destroying VM and associated drives...
~/projects/vagrant-c7-docker-oraclexe $ vagrant up
Bringing machine 'master1' up with 'virtualbox' provider...
==> master1: Importing base box 'https://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1804_02.VirtualBox.box'...
==> master1: Matching MAC address for NAT networking...
...
```






