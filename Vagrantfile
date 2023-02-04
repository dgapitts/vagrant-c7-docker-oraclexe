# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
  end

# Database server 1.
config.vm.define "master1" do |master|
  master.vm.hostname = "c7-master"
  master.vm.box = "https://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1804_02.VirtualBox.box"
  master.vm.network :private_network, ip: "192.168.60.55"
  master.vm.provision :shell, :path => "master.sh"
end
end

