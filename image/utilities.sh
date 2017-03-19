#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Often used tools.
$minimal_apt_get_install curl less vim-tiny psmisc
ln -s /usr/bin/vim.tiny /usr/bin/vim

## Jinja 2 templates
$minimal_apt_get_install python3-jinja2

## This tool runs a command as another user and sets $HOME.
cp /bd_build/bin/setuser /sbin/setuser
