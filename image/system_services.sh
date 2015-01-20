#!/bin/bash
set -e
set -x

## Install init process.
cp /build/bin/my_init /sbin/
mkdir -p /etc/my_init.d
mkdir -p /etc/container_environment
touch /etc/container_environment.sh
touch /etc/container_environment.json
chmod 700 /etc/container_environment

groupadd -g 8377 docker_env
chown :docker_env /etc/container_environment.sh /etc/container_environment.json
chmod 640 /etc/container_environment.sh /etc/container_environment.json
ln -s /etc/container_environment.sh /etc/profile.d/

## Install runit.
apt-get install runit

## Install a syslog daemon.
apt-get install syslog-ng-core
mkdir /etc/service/syslog-ng
cp /build/runit/syslog-ng /etc/service/syslog-ng/run
mkdir -p /var/lib/syslog-ng
cp /build/config/syslog_ng_default /etc/default/syslog-ng
# Replace the system() source because inside Docker we
# can't access /proc/kmsg.
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf

## Install logrotate.
apt-get install logrotate

## Install the SSH server.
apt-get install openssh-server
mkdir /var/run/sshd
mkdir /etc/service/sshd
cp /build/runit/sshd /etc/service/sshd/run
cp /build/config/sshd_config /etc/ssh/sshd_config
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

## Install cron daemon.
apt-get install cron
mkdir /etc/service/cron
cp /build/runit/cron /etc/service/cron/run

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
