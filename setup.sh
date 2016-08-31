#!/bin/bash
set -eu

[ -z "${DEBUG-}" ] || set -x

ANSIBLE_SETUP_DIR=${ANSIBLE_SETUP_DIR:-~/.ansible-setup}
OS=$(lsb_release -si)
VERSION=$(lsb_release -sr)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# apt_get_install $@
#   Retry-ing wrapper around apt_get_install, because apt-cacher-ng is unstable,
#   and because the Retries apt configuration done in set_apt_proxy does not
#   apply to headers.
#
apt_get_install() {
    local n=0

    until [ $n -ge 50 ]; do
        sudo apt-get -y install $@ && return 0 || echo failed apt-get install
        apt_get_update

        # Sleep 0 seconds first as the apt_get_update call might fix apt-get
        # install !
        sleep $((60*n))
        n=$((n+1))
    done

    return 1
}

# apt_get_update [<retries=20>] [<sleep=60>]
#   Retry-ing wrapper around apt-get update, because apt-cacher-ng is unstable,
#   and because the Retries apt configuration done in set_apt_proxy does not
#   apply to headers.
#   This will run `apt-get -qy update`, if it fails then sleep during a
#   incremental time before retrying (<number of tries>*$sleep).
#
apt_get_update() {
    local n=0
    until [ $n -ge ${1-20} ]; do
        sudo apt-get -qy update && return 0 || echo failed apt-get update
        n=$((n+1))
        sleep $((n*${2-60}))
    done

    return 1
}

hash git &> /dev/null || apt_get_install git

if ! hash python2 &> /dev/null; then
    if hash apt-cache; then
        if apt-cache search python2 | grep '^python2 '; then
            apt_get_install python2
        elif apt-cache search python | grep '^python '; then
            apt_get_install python
        else
            echo 'Could not install python'
            exit 1
        fi
    fi
fi

if ! [ -f /usr/include/python2.7/Python.h ]; then
    if hash apt-cache; then
        if apt-cache search python2-dev | grep '^python2-dev '; then
            apt_get_install python2-dev
        elif apt-cache search python-dev | grep '^python-dev '; then
            apt_get_install python-dev
        else
            echo 'Could not install python-dev'
            exit 1
        fi
    fi
fi

if ! hash virtualenv &> /dev/null && ! hash virtualenv2 &> /dev/null; then
    if hash apt-cache; then
        if apt-cache search python2-virtualenv | grep '^python2-virtualenv '; then
            apt_get_install python2-virtualenv
        elif apt-cache search python-virtualenv | grep '^python-virtualenv '; then
            apt_get_install python-virtualenv
        else
            echo 'Could not install virtualenv'
            exit 1
        fi
    fi
fi

hash virtualenv2 &> /dev/null && virtualenv=virtualenv2 || virtualenv=virtualenv

if [ ! -d $ANSIBLE_SETUP_DIR ]; then
    mkdir -p $ANSIBLE_SETUP_DIR
fi

if [ ! -f $ANSIBLE_SETUP_DIR/bin/activate ]; then
    $virtualenv $ANSIBLE_SETUP_DIR
fi

set +u  # activate is not compatible with -u
source $ANSIBLE_SETUP_DIR/bin/activate
set -u

if [ $(pip --version | cut -f2 -d' ' | sed 's/\..*//') -lt 8 ]; then
    pip install --upgrade pip
fi

if [ $(easy_install --version | cut -f2 -d' ' | sed 's/\..*//') -lt 20 ]; then
    pip install --upgrade setuptools
fi

if [ -z "$(find /usr/include/ -name e_os2.h)" ]; then
    if hash apt-get &> /dev/null; then
        apt_get_install libssl-dev
    fi
fi

if [ -z "$(find /usr/include/ -name ffi.h)" ]; then
    if hash apt-get &> /dev/null; then
        apt_get_install libffi-dev
    fi
fi

if ! hash ansible-playbook &> /dev/null; then
    pip install --upgrade --editable git+https://github.com/ansible/ansible.git@devel#egg=ansible
fi

if [ ! -e ~/.ansible.cfg ]; then
    ln -sfn ~/.ansible-setup/ansible.cfg ~/.ansible.cfg
fi

if [ -n "${SETUP_LXC-}" ]; then
    if [ "$OS" = "Ubuntu" ]; then
        sudo add-apt-repository --yes ppa:ubuntu-lxc/stable
        apt_get_update
        apt_get_install dnsmasq lxc lxc-dev

        sudo sed -i 's/^#LXC_DOMAIN="lxc"/LXC_DOMAIN="lxc"/' /etc/default/lxc-net
        sudo service lxc-net restart

        if ! grep 'server=/lxc/10.0.3.1' /etc/dnsmasq.d/lxc ; then
            echo server=/lxc/10.0.3.1 | sudo tee -a /etc/dnsmasq.d/lxc
            sudo service dnsmasq restart
        fi
    fi

    if ! python -c 'import lxc' &> /dev/null; then
        LC_ALL=C $ANSIBLE_SETUP_DIR/bin/pip install lxc-python2
    fi
fi

if [ -n "${SETUP_LXD-}" ]; then
    if [ "$OS" = "Ubuntu" ]; then
        echo lxd    lxd/bridge-ipv4-dhcp-first    string    10.0.40.2 | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv4-netmask    string    24 | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv6-address    string | sudo debconf-set-selections
        echo lxd    lxd/bridge-http-proxy    boolean    false | sudo debconf-set-selections
        echo lxd    lxd/bridge-dnsmasq    string | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv4-dhcp-leases    string    252 | sudo debconf-set-selections
        echo lxd    lxd/bridge-empty-error    note | sudo debconf-set-selections
        echo lxd    lxd/setup-bridge    boolean    true | sudo debconf-set-selections
        echo lxd    lxd/bridge-random-warning    note | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv4-nat    boolean    true | sudo debconf-set-selections
        echo lxd    lxd/use-existing-bridge    boolean    false | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv4-dhcp-last    string    10.0.40.254 | sudo debconf-set-selections
        echo lxd    lxd/bridge-name    string    lxdbr0 | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv6-nat    boolean    false | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv6    boolean    false | sudo debconf-set-selections
        echo lxd    lxd/bridge-domain    string    lxd | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv4    boolean    true | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv6-netmask    string | sudo debconf-set-selections
        echo lxd    lxd/bridge-ipv4-address    string    10.0.40.1 | sudo debconf-set-selections
        echo lxd    lxd/bridge-upgrade-warning    note | sudo debconf-set-selections
        echo lxd    lxd/update-profile    boolean    true | sudo debconf-set-selections
        sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-stable
        sudo apt-get update -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y lxd dnsmasq
        sudo lxd init --auto
        sudo gpasswd -a $USER lxd
        sg lxd 'lxc list'

        if [ ! -f /etc/dnsmasq.d/lxd ] ; then
            echo server=/lxd/10.0.40.1 | sudo tee -a /etc/dnsmasq.d/lxd
            echo except-interface=lxdbr0 | sudo tee -a /etc/dnsmasq.d/lxd
            sudo service dnsmasq restart
        fi
    fi
fi

always_activate() {
  if [ ! -f ~/.bashrc ] || ! grep 'source.*activate' ~/.bashrc; then
    echo '# Activate ansible virtualenv' >> ~/.bashrc
    echo "source $ANSIBLE_SETUP_DIR/bin/activate" >> ~/.bashrc
    echo 'export ANSIBLE_STDOUT_CALLBACK=debug' >> ~/.bashrc
    echo '!! You need to login again for changes to take effect !!'
  fi
}

if [[ $- == *i* ]]; then
  while true; do
    read -p "Do you wish to activate ansible setup in your shell ? "  yn
    case $yn in
      y ) always_activate; break;;
      n ) exit;;
      * ) echo "Please answer y or n.";;
    esac
  done
elif [ "${ALWAYS_ACTIVATE-1}" = "1" ]; then
    always_activate
fi
