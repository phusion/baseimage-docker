#!/bin/bash
set -e
source /build/buildconfig
set -x

## Enable Ubuntu Universe.
echo deb http://archive.ubuntu.com/ubuntu precise main universe > /etc/apt/sources.list
echo deb http://archive.ubuntu.com/ubuntu precise-updates main universe >> /etc/apt/sources.list
apt-get update

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

## Upgrade all packages.
echo "initscripts hold" | dpkg --set-selections
apt-get upgrade -y --no-install-recommends

## Fix locale.
$minimal_apt_get_install language-pack-en
locale-gen en_US
