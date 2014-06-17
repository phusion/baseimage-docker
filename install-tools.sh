#!/bin/bash
set -e
dir=`dirname "$0"`
cd "$dir"

set -x
cp tools/* /usr/local/bin/
mkdir -p /usr/local/share/baseimage-docker
cp image/insecure_key /usr/local/share/baseimage-docker/
chmod 644 /usr/local/share/baseimage-docker/insecure_key
