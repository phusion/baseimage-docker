#!/bin/bash
set -e
source /build/buildconfig
set -x

$minimal_apt_get_install cron
mkdir /etc/service/cron
cp /build/services/cron/cron.runit /etc/service/cron/run

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
