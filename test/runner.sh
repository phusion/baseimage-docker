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

PWD=`pwd`

echo " --> Starting insecure container"
ID=`docker run -d -v $PWD/test:/test $NAME:$VERSION /sbin/my_init --enable-insecure-key`
sleep 1

echo " --> Obtaining IP"
IP=`docker inspect -f "{{ .NetworkSettings.IPAddress }}" "$ID"`
if [[ "$IP" = "" ]]; then
	abort "Unable to obtain container IP"
fi

trap cleanup EXIT

echo " --> Enabling SSH in the container"
docker exec -t -i $ID /etc/my_init.d/00_regen_ssh_host_keys.sh -f
docker exec -t -i $ID rm /etc/service/sshd/down
docker exec -t -i $ID sv start /etc/service/sshd
sleep 1

echo " --> Logging into container and running tests"
cp image/services/sshd/keys/insecure_key /tmp/insecure_key
chmod 600 /tmp/insecure_key
sleep 1 # Give container some more time to start up.
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /tmp/insecure_key root@$IP \
	/bin/bash /test/test.sh
