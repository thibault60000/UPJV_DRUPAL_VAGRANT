# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.hostname = 'my-project.local'
  config.vm.box = 'ubuntu/xenial64'
  
  config.vm.network "forwarded_port", 
    guest: 80, 
    host: 8090
  	
  config.vm.synced_folder '.', '/var/www', 
  create: true, 
  owner: 'www-data', 
  group: 'www-data', 
  mount_options: ["dmode=775,fmode=664"]

  config.vm.provider "virtualbox" do |vb|
	vb.name = 'my-project - Ubuntu 16.04'
	vb.memory = 1024
	vb.cpus = 2
  end
    
  config.vm.provision 'shell', path: 'provision.sh'
end