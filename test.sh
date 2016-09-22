#!/bin/bash
set -eux

LXD_NAME=${LXD_NAME-test-trusty}
LXD_IMAGE=${LXD_IMAGE-ubuntu:14.04}
ANSIBLE_SETUP="${ANSIBLE_SETUP-$PWD/ansible-setup}"
TESTENV=testenv

source $ANSIBLE_SETUP

if [ -z ${1-} ]; then
    for i in tests/*; do
        source $i
    done
else
    source tests/$1
fi
