#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

$minimal_apt_get_install cron
mkdir /etc/service/cron
chmod 600 /etc/crontab
cp /bd_build/services/cron/cron.runit /etc/service/cron/run

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim
