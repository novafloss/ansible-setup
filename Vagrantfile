# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  boxes = ['ubuntu/trusty64', 'debian/jessie64']

  boxes.each do |boxname|
    config.vm.define boxname.sub(%r{.*/}, '') do |box|
      box.vm.box = boxname

      box.vm.provision "shell", inline: <<-SHELL
        cd /home/vagrant
        sudo --set-home -u vagrant SETUP_LXD=1 SETUP_LXC=1 DEBUG=1 /vagrant/setup.sh
      SHELL
    end
  end
end
