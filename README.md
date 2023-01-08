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

### Setup simple test - one million row table

```
set timing on
create table t1m (id integer, f1 varchar2(100));
insert into t1m (id, f1) select level, 'blah blah blah blah blah blah blah blah blah blah blah blah' f1 from dual connect by 1=1 and level <= 1000000;


set autotrace traceonly
select * from t1m;
select * from t1m;
```

