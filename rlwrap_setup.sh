##  to be run as oracle after downloading the docker image
su - root -c "yum install -y oracle-epel-release-el7"
su - root -c "yum install -y rlwrap less vi"
echo "alias sql+='rlwrap sqlplus / as sysdba'" >> .bash_profile