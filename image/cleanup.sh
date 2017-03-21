#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

apt-get clean
ls -d -1 /bd_build/**/* | grep -v "cleanup.sh" | grep -v "buildconfig" | grep -v "services/" | xargs rm -f
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*

rm -f /etc/ssh/ssh_host_*
