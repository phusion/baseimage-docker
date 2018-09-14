#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

SYSLOG_NG_BUILD_PATH=/bd_build/services/syslog-ng

## Install a syslog daemon.
$minimal_apt_get_install syslog-ng-core
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.init /etc/my_init.d/10_syslog-ng.init
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.shutdown /etc/my_init.post_shutdown.d/10_syslog-ng.shutdown
mkdir -p /var/lib/syslog-ng
cp $SYSLOG_NG_BUILD_PATH/syslog_ng_default /etc/default/syslog-ng
touch /var/log/syslog
chmod u=rw,g=r,o= /var/log/syslog
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

## Install logrotate.
$minimal_apt_get_install logrotate
cp $SYSLOG_NG_BUILD_PATH/logrotate.conf /etc/logrotate.conf
cp $SYSLOG_NG_BUILD_PATH/logrotate_syslogng /etc/logrotate.d/syslog-ng
