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
ID=`docker run --env=AUTHORIZED_KEYS="$(ssh-add -L)" -d -v $PWD/test:/test $NAME:$VERSION`
sleep 1

echo " --> Obtaining IP"
IP=`docker inspect --format='{{ .NetworkSettings.IPAddress }}' $ID`
if [[ "$IP" = "" ]]; then
	abort "Unable to obtain container IP"
fi

trap cleanup EXIT

echo " --> Enabling SSH in the container"
docker exec $ID sv start /etc/service/sshd
sleep 1

echo " --> Logging into container and running tests"
sleep 1 # Give container some more time to start up.
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP \
	/bin/bash /test/test.sh
