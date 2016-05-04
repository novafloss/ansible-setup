#!/bin/bash
set -eu

[ -z "${DEBUG-}" ] || set -x

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

if [ ! -e ~/.ansible-setup ]; then
    ln -sfn $DIR ~/.ansible-setup
fi

if ! hash python2 &> /dev/null; then
    if hash apt-cache; then
        if apt-cache search python2 | grep '$python2 '; then
            apt_get_install python2
        elif apt-cache search python | grep '$python '; then
            apt_get_install python
        fi
    fi
fi

if [ ! -f /usr/include/python2.7/Python.h ]; then
    if hash apt-cache; then
        if apt-cache search python2-dev | grep '$python2-dev '; then
            apt_get_install python2-dev
        elif apt-cache search python-dev | grep '$python-dev '; then
            apt_get_install python-dev
        fi
    fi
fi

if ! hash virtualenv &> /dev/null && ! hash virtualenv2 &> /dev/null; then
    if hash apt-cache; then
        if [ -n "$(apt-cache search python2-virtualenv)" ]; then
            apt_get_install python2-virtualenv
        elif [ -n "$(apt-cache search python-virtualenv)" ]; then
            apt_get_install python-virtualenv
        fi
    fi
fi

hash virtualenv2 &> /dev/null && virtualenv=virtualenv2 || virtualenv=virtualenv

if [ ! -d ~/.ansible-setup/ansible_env ]; then
    mkdir -p ~/.ansible-setup
    $virtualenv ~/.ansible-setup/ansible_env
fi

set +u  # activate is not compatible with -u
source ~/.ansible-setup/ansible_env/bin/activate
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

# User doesn't have a default virtualenv, let's configure one
if [ ! -f ~/.bashrc ] || ! grep 'source.*activate' ~/.bashrc; then
    echo '# Activate ansible virtualenv' >> ~/.bashrc
    echo 'source ~/.ansible-setup/ansible_env/bin/activate' >> ~/.bashrc
    echo '!! You need to login again for changes to take effect !!'
fi

if [ ! -e ~/.ansible.cfg ]; then
    ln -sfn ~/.ansible-setup/ansible.cfg ~/.ansible.cfg
fi

#if ! hash lxc-create &> /dev/null; then
#    if hash apt-cache; then
#        if apt-cache search lxc; then
#            apt_get_install lxc
#        fi
#    fi
#fi
#
#if [ ! -f /usr/include/lxc/lxccontainer.h ]; then
#    if hash apt-cache; then
#        if apt-cache search lxc-dev; then
#            apt_get_install lxc-dev
#        fi
#    fi
#fi
#
#if ! python -c 'import lxc' &> /dev/null; then
#    pip install python2-lxc
#fi


if [ -n "${SETUP_LXC-}" ]; then
    pushd ~/.ansible-setup
    mkdir -p roles
    ansible-galaxy install -p roles git+https://github.com/toopy/ansible-role-lxc-dev.git
    ansible-playbook -i localhost, lxc.yml
    popd
fi
