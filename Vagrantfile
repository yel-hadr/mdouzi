Vagrant.configure("2") do |config|
    config.vm.box = "debian/bookworm64"
    config.vm.synced_folder ".", "/vagrant"
  
    config.vm.define "yelhadrS", primary: true do |yelhadrS|
      yelhadrS.vm.hostname = "yelhadrS"
      yelhadrS.vm.network "private_network", ip: "192.168.56.110"
      yelhadrS.vm.network "forwarded_port", guest: 8888, host: 8888
  
      yelhadrS.vm.provider "virtualbox" do |vb|
        vb.name   = "yelhadrS-p3"
        vb.memory = 4096
        vb.cpus   = 2
      end
  
      yelhadrS.vm.provision "shell", path: "scripts/setup.sh"
    end
  end