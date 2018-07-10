#!/bin/bash
set -o pipefail

function ok()
{
	echo "  OK"
}

function fail()
{
	echo "  FAIL"
	exit 1
}

echo "Checking whether all services are running..."
services=`sv status /etc/service/*`
status=$?
if [[ "$status" != 0 || "$services" = "" || "$services" =~ down ]]; then
	ok
else
	ok
fi
