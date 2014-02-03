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

echo " --> Starting container"
PWD=`pwd`
ID=`docker run -d -v $PWD/test:/test $NAME:$VERSION`
sleep 1

echo " --> Obtaining IP"
IP=`docker inspect $ID | grep IPAddress | sed -e 's/.*: "//; s/".*//'`
if [[ "$IP" = "" ]]; then
	abort "Unable to obtain container IP"
fi

trap cleanup EXIT

echo " --> Logging into container and running tests"
chmod 600 image/insecure_key
sleep 1 # Give container some more time to start up.
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i image/insecure_key root@$IP \
	/bin/bash /test/test.sh
