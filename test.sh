#!/bin/bash
set -eux

LXD_NAME=${LXD_NAME-test-trusty}
LXD_IMAGE=${LXD_IMAGE-ubuntu:14.04}
ANSIBLE_SETUP="${1-./ansible-setup}"
TESTENV=testenv

source $ANSIBLE_SETUP

teardown() {
    rm -rf $TESTENV
}
trap teardown EXIT INT QUIT TERM ABRT ALRM HUP
rm -rf $TESTENV
VIRTUALENV_PATH=$TESTENV $ANSIBLE_SETUP ansible_ref_require stable-2.1
$TESTENV/bin/ansible --version

lxd_require || echo 'Not ubuntu, lets hope it works !'

sg lxd "lxc info $LXD_NAME || lxc launch $LXD_IMAGE $LXD_NAME && lxc info $LXD_NAME | grep Running || lxc start $LXD_NAME"
sg lxd "lxc file push $ANSIBLE_SETUP $LXD_NAME/ansible-setup"
sg lxd "lxc exec $LXD_NAME bash -- -c 'until getent hosts google.com; do sleep .1; done'"
sg lxd "lxc exec $LXD_NAME /ansible-setup -- ansible_ref_require stable-2.1 /usr/bin"
sg lxd "lxc exec $LXD_NAME ansible -- --version" | grep 2.1
sg lxd "lxc exec $LXD_NAME test -- -f /usr/bin/ansible"
sg lxd "lxc exec $LXD_NAME test -- -f /root/.ansible-env/bin/ansible"
sg lxd "lxc exec $LXD_NAME test -- -f /root/.ansible-env/src/ansible/lib/ansible/modules/core/__init__.py"
sg lxd "lxc exec $LXD_NAME test -- -f /root/.ansible-env/src/ansible/lib/ansible/modules/extras/__init__.py"
sg lxd "lxc exec $LXD_NAME --env VIRTUALENV_PATH=/root/ansible-devel /ansible-setup -- ansible_ref_require devel"
sg lxd "lxc exec $LXD_NAME ansible -- --version" | grep 2.1
sg lxd "lxc exec $LXD_NAME /root/ansible-devel/bin/ansible -- --version" | grep 2.2
