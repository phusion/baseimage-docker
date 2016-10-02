#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

SYSLOG_NG_BUILD_PATH=/bd_build/services/syslog-ng

## Install a syslog daemon.
$minimal_apt_get_install syslog-ng-core
mkdir /etc/service/syslog-ng
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.runit /etc/service/syslog-ng/run
mkdir -p /var/lib/syslog-ng
cp $SYSLOG_NG_BUILD_PATH/syslog_ng_default /etc/default/syslog-ng
touch /var/log/syslog
chmod u=rw,g=r,o= /var/log/syslog
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

## Install syslog to "docker logs" forwarder.
mkdir /etc/service/syslog-forwarder
cp $SYSLOG_NG_BUILD_PATH/syslog-forwarder.runit /etc/service/syslog-forwarder/run

## Install logrotate.
$minimal_apt_get_install logrotate
cp $SYSLOG_NG_BUILD_PATH/logrotate_syslogng /etc/logrotate.d/syslog-ng

## Change logrotate default group
sed -i 's/su root syslog/su root adm/' /etc/logrotate.conf
