#!/bin/bash
set -e
if [[ ! -e /etc/ssh/ssh_host_rsa_key ]]; then
	echo "No SSH host key available. Generating one..."
	dpkg-reconfigure openssh-server
fi
