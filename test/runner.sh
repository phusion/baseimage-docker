#!/bin/bash
set -e

function abort()
{
	echo "$@"
	exit 1
}

function cleanup()
{
	echo " --> Stopping container"
	docker stop $ID >/dev/null
	docker rm $ID >/dev/null
}

echo " --> Starting insecure container"
ID=`docker run -d -p 22 $NAME:$VERSION /sbin/my_init --enable-insecure-key`
sleep 1

echo " --> Obtaining SSH port number"
SSHPORT=`docker inspect --format='{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}' "$ID"`
if [[ "$SSHPORT" = "" ]]; then
	abort "Unable to obtain container SSH port number"
fi

trap cleanup EXIT

echo " --> Enabling SSH in the container"
docker exec $ID /etc/my_init.d/00_regen_ssh_host_keys.sh -f
docker exec $ID rm /etc/service/sshd/down
docker exec $ID sv start /etc/service/sshd
sleep 1

echo " --> Logging into container and running tests"
sleep 1 # Give container some more time to start up.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
tools/docker-ssh $ID bash < test/test.sh
