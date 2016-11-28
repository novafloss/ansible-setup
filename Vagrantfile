# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  boxes = ['ubuntu/trusty64']

  boxes.each do |boxname|
    config.vm.define boxname.sub(%r{.*/}, '') do |box|
      box.vm.box = boxname

      box.vm.provision "shell", inline: <<-SHELL
        cd /vagrant
        ./test.sh
      SHELL
    end
  end
end
