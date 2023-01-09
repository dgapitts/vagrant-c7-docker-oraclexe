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




