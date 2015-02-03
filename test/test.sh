#!/bin/bash
set -o pipefail

function ok()
{
	echo "  OK"
}

function fail()
{
	echo "  FAIL ($1)"
	exit 1
}

echo "Checking whether all services are running..."
services=$(echo /etc/service/* | xargs sv check)
status=$?
if [[ "$status" != 0 ]]; then
	fail "status $status"
elif [[ "$services" = "" ]]; then
	fail "no output"
elif echo "$services" | grep -v '^ok: run: /etc/service/' | grep . ; then
	fail "service down"
else
	ok
fi
