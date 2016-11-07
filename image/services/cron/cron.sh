#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

$minimal_apt_get_install cron
chmod 600 /etc/crontab

## Enable runit
install -D -m 755  /bd_build/services/cron/cron.runit /etc/sv/cron/run
ln -s /etc/sv/cron /etc/service

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim
