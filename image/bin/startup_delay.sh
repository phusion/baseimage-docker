#!/bin/sh -e

# If the STARTUP_DELAY environment variable is set, the container
#  startup is delayed by that many seconds.
if [ "x$STARTUP_DELAY" != "x" ]; then
    echo "Delaying container startup for $STARTUP_DELAY seconds"
    sleep $STARTUP_DELAY || true
fi
