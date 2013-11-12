#!/bin/bash
set -e
source /build/buildconfig
set -x

## Often used tools.
apt-get install -y curl less nano vim psmisc

## This tool runs a command as another user and sets $HOME.
cp /build/setuser /sbin/setuser
