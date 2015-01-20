#!/bin/bash
set -e
set -x

## Often used tools.
apt-get install curl less nano vim psmisc

## This tool runs a command as another user and sets $HOME.
cp /build/bin/setuser /sbin/setuser
