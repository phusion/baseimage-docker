#!/bin/bash
set -e

if [[ -f /etc/service/sshd/down ]] ; then
	rm /etc/service/sshd/run
	echo "SSH is disabled. To enable it, remove '/etc/service/sshd/down'."
else

	if [[ ! -e /etc/ssh/ssh_host_rsa_key ]] || [[ "$1" == "-f" ]]; then
		echo "No SSH host key available. Generating one..."
		export LC_ALL=C
		export DEBIAN_FRONTEND=noninteractive
		dpkg-reconfigure openssh-server
	fi
fi
