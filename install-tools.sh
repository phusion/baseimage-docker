#!/bin/sh
set -e
dir=`dirname "$0"`
cd "$dir"

set -x
cp tools/docker-bash /usr/local/bin/
cp tools/docker-ssh /usr/local/bin/
mkdir -p /usr/local/share/baseimage-docker
cp image/services/sshd/keys/insecure_key /usr/local/share/baseimage-docker/
chmod 644 /usr/local/share/baseimage-docker/insecure_key
