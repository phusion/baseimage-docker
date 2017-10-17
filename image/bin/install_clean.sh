#!/bin/sh
#  Apt installer helper for Docker images

set -e

echo "Installing $*"
apt-get -q update && apt-get -qy install $* \
    && apt-get -qy autoremove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*
