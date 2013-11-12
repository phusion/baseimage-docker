#!/bin/bash
set -e
source /build/buildconfig
set -x

## Install init process.
cp /build/my_init /sbin/

## Install runit.
apt-get install -y runit

## Install a syslog daemon.
apt-get install -y syslog-ng
mkdir /etc/service/syslog-ng
cp /build/runit/syslog-ng /etc/service/syslog-ng/run

## Install the SSH server.
apt-get install -y openssh-server
mkdir /var/run/sshd
mkdir /etc/service/sshd
cp /build/runit/sshd /etc/service/sshd/run
cp /build/config/sshd_config /etc/ssh/sshd_config

## Install default SSH key for root and app.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown root:root /root/.ssh
cat /build/insecure_key.pub > /root/.ssh/authorized_keys
