#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

apt-get clean
find /bd_build/ -not \( -name 'bd_build' -or -name 'buildconfig' -or -name 'cleanup.sh' \) -delete
rm -rf /tmp/* /var/tmp/*
rm -f /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/*cache.bin
rm -rf /var/lib/apt/lists/*

rm -f /etc/ssh/ssh_host_*
