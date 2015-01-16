#!/bin/bash
set -e
source /build/buildconfig
set -x

$minimal_apt_get_install syslog-ng-core logrotate
mkdir /etc/service/syslog-ng
cp /build/services/syslog-ng/syslog-ng.runit /etc/service/syslog-ng/run
mkdir -p /var/lib/syslog-ng
cp /build/services/syslog-ng/syslog_ng_default /etc/default/syslog-ng
# Replace the system() source because inside Docker we
# can't access /proc/kmsg.
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf
