novafloss/ansible-setup
~~~~~~~~~~~~~~~~~~~~~~~

ansible-setup is a standalone bash script providing setup functions for ansible
and lxc/lxd, which we use to test ansible playbooks, with the following
constraints:

- automatic lxc/lxd basic configuration for ubuntu users only, including travis
- resolvable containers: host should resolve name.lxc and name.lxd
- install ansible in a virtualenv to support having several versions installed
- speed: avoid paramiko dependency, use apt python crypto binaries
- modularity: using bash functions
- hack: support installing particular revisions of ansible for happy hacking

Why ?
=====

With this, we can setup the necessary environment to run the novafloss boot
roles which we use for testing, locally, on our jenkins servers or even on
travis for open source roles.

Upgrading from setup.sh
=======================

Previously, we had a straightforward setup.sh script supporting one of our
team's use-case and distribution. Now that our userbase has grown, new feedback
has been collected, leading to this new version.

To upgrade, run any of the following examples, but feel free to delete any
leftover from setup.sh::

    # Uninstall
    rm -rf ~/.ansible-env ~/.ansible-setup
    unlink ~/.ansible.cfg
    sed -i '/source.*ansible-env/d' ~/.bashrc

    # Reinstall
    wget https://raw.githubusercontent.com/novafloss/ansible-setup/master/ansible-setup
    bash ansible-setup ansible_ref_require devel /usr/bin # or use stable-2.1 here
    bash ansible-setup python2_lxc_require

Examples
========

Download the script::

    wget https://raw.githubusercontent.com/novafloss/ansible-setup/master/ansible-setup
    chmod +x ansible-setup

Unattented lxc install on ubuntu::

    ./ansible-setup lxc_require

Unattended lxd install on ubuntu::

    ./ansible-setup lxd_require

Install ansible branch stable-2.1 in /usr/bin with the virtualenv in
~/.ansible-env::

    ./ansible-setup ansible_ref_require stable-2.1 /usr/bin
    ansible --version  # would show 2.1

Install ansible devel in a virtualenv in ~/.ansible-devel::

    VIRTUALENV_PATH=~/.ansible-devel ./ansible-setup ansible_ref_require devel
    ~/ansible-devel/bin/ansible --version  # would show 2.2
