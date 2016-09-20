# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  boxes = ['ubuntu/trusty64']

  boxes.each do |boxname|
    config.vm.define boxname.sub(%r{.*/}, '') do |box|
      box.vm.box = boxname

      box.vm.provision "shell", inline: <<-SHELL
        set -eux
        cd /home/vagrant
        sudo --set-home -u vagrant /vagrant/ansible-setup lxc_require
        sudo --set-home -u vagrant /vagrant/ansible-setup lxd_require
        sudo --set-home -u vagrant /vagrant/ansible-setup ansible_ref_require stable-2.1 /usr/bin
        sudo --set-home -u vagrant /vagrant/ansible-setup lxc_python2_require
        sudo --set-home -u vagrant /vagrant/test.sh /vagrant/ansible-setup
      SHELL
    end
  end
end
