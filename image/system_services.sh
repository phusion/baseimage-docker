#!/bin/bash
set -e
source /build/buildconfig
set -x

## Install init process.
cp /build/my_init /sbin/
mkdir -p /etc/my_init.d

## Install runit.
$minimal_apt_get_install runit

## Install a syslog daemon.
$minimal_apt_get_install syslog-ng-core
mkdir /etc/service/syslog-ng
cp /build/runit/syslog-ng /etc/service/syslog-ng/run

## Install the SSH server.
$minimal_apt_get_install openssh-server
mkdir /var/run/sshd
mkdir /etc/service/sshd
cp /build/runit/sshd /etc/service/sshd/run
cp /build/config/sshd_config /etc/ssh/sshd_config
cp /build/00_regen_ssh_host_keys.sh /etc/my_init.d/

## Install default SSH key for root and app.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown root:root /root/.ssh
cat /build/insecure_key.pub > /root/.ssh/authorized_keys

## Install cron daemon.
$minimal_apt_get_install cron
mkdir /etc/service/cron
cp /build/runit/cron /etc/service/cron/run
