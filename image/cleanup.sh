#!/bin/bash
set -e
source /build/buildconfig
set -x

apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /build
