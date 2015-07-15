#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Often used tools.
$minimal_apt_get_install curl less nano vim psmisc

## This tool runs a command as another user and sets $HOME.
cp /bd_build/bin/setuser /sbin/setuser
