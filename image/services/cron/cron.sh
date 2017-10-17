#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

$minimal_apt_get_install cron
mkdir /etc/service/cron
chmod 600 /etc/crontab
cp /bd_build/services/cron/cron.runit /etc/service/cron/run
# Fix cron issues in 0.9.19, see also #345: https://github.com/phusion/baseimage-docker/issues/345
sed -i 's/^\s*session\s\+required\s\+pam_loginuid.so/# &/' /etc/pam.d/cron

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim

# Add my_cron/ dirs
mkdir /etc/my_cron.d
mkdir /etc/my_cron.hourly
mkdir /etc/my_cron.daily
mkdir /etc/my_cron.weekly
mkdir /etc/my_cron.monthly

cp /bd_build/services/cron/init_cron.sh /etc/my_init.d/05_init_cron.sh
