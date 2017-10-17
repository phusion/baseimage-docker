#!/bin/bash -e
#  Apt installer helper for Docker images

ARGS="$*"
NO_RECOMMENDS="--no-install-recommends"
RECOMMENDS="--install-recommends"
if [[ $ARGS =~ "$RECOMMENDS" ]]; then
    NO_RECOMMENDS=""
    ARGS=$(sed "s/$RECOMMENDS//g" <<<"$ARGS")
fi

echo "Installing $ARGS"

apt-get -q update && apt-get -qy install $NO_RECOMMENDS $ARGS \
    && apt-get -qy autoremove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*
