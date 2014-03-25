#!/bin/bash
set -e
source /build/buildconfig
set -x

## Temporarily disable dpkg fsync to make building faster.
echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/02apt-speedup

## Enable Ubuntu Universe and Multiverse.
cp /build/sources.list /etc/apt/sources.list
apt-get update

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Upgrade all packages.
echo "initscripts hold" | dpkg --set-selections
apt-get upgrade -y --no-install-recommends

## Fix locale.
$minimal_apt_get_install language-pack-en
locale-gen en_US
