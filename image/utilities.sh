#!/bin/bash
set -e
source /build/buildconfig
set -x

## Often used tools.
$minimal_apt_get_install wget curl less nano vim psmisc

## This tool runs a command as another user and sets $HOME.
cp /build/bin/setuser /sbin/setuser


## install busybox for wget and telnet,...
#/usr/lib/initramfs-tools/bin/busybox  is too old
#if [ ! -f /usr/lib/initramfs-tools/bin/busybox  ] ; then
curl  http://www.busybox.net/downloads/binaries/latest/busybox-x86_64 > /usr/local/bin/busybox
chmod +x /usr/local/bin/busybox
#else
#ln -s /usr/lib/initramfs-tools/bin/busybox   /usr/local/bin/busybox
#fi
#ln -s $(which busybox) /usr/local/bin/wget
ln -s $(which busybox) /usr/local/bin/telnet
ln -s $(which busybox) /usr/local/bin/unzip
ln -s $(which busybox) /usr/local/bin/xz
