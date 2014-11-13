#!/bin/bash
set -e
source /build/buildconfig
set -x

$minimal_apt_get_install openssh-server
mkdir /var/run/sshd
mkdir /etc/service/sshd
cp /build/services/sshd/sshd.runit /etc/service/sshd/run
cp /build/services/sshd/sshd_config /etc/ssh/sshd_config
cp /build/00_regen_ssh_host_keys.sh /etc/my_init.d/

## Install default SSH key for root and app.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown root:root /root/.ssh
cp /build/insecure_key.pub /etc/insecure_key.pub
cp /build/insecure_key /etc/insecure_key
chmod 644 /etc/insecure_key*
chown root:root /etc/insecure_key*
cp /build/bin/enable_insecure_key /usr/sbin/
