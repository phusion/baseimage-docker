#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

apt-get clean
rm -rf /bd_build
rm -rf /tmp/* /var/tmp/*
rm -f /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/*cache.bin
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup

rm -f /etc/ssh/ssh_host_*
