#! /bin/bash
if [ ! -f /home/vagrant/already-installed-flag ]
then
  echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
  echo "ADD EXTRA ALIAS VIA .bashrc"
  cat /vagrant/bashrc.append.txt >> /home/vagrant/.bashrc
  cat /vagrant/bashrc.append.txt >> /root/.bashrc 


  #echo "GENERAL YUM UPDATE"
  #yum -y update
  #echo "INSTALL GIT"




else
  echo "already installed flag set : /home/vagrant/already-installed-flag"
fi

