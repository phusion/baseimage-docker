#!/bin/bash
set -e

# # Prepare qemu
# if [ '$QEMU_ARCH' != 'amd64' ]; then
#     # docker run --rm --privileged multiarch/qemu-user-static:register --reset
# fi

# Get qemu package
echo "Getting qemu package for $QEMU_ARCH"

# Fake qemu for amd64 builds to avoid breaking COPY in Dockerfile
if [[ $QEMU_ARCH == "amd64" ]]; then
	touch x86_64_qemu-"$QEMU_ARCH"-static.tar.gz
	mv x86_64_qemu-${QEMU_ARCH}-static.tar.gz image
else
	curl -L -o x86_64_qemu-"$QEMU_ARCH"-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/"$QEMU_VERSION"/x86_64_qemu-"$QEMU_ARCH"-static.tar.gz
	mv x86_64_qemu-${QEMU_ARCH}-static.tar.gz image
fi
