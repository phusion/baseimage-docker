#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

# Fixes https://github.com/docker/docker/issues/6345
# The Github is closed, but some apps such as pbuilder still triggers it.

export CONFIGURE_OPTS=--disable-audit
cd /tmp

$minimal_apt_get_install gdebi-core
apt-get build-dep -y --no-install-recommends pam
apt-get source -y -b pam
gdebi -n libpam-doc*.deb libpam-modules*.deb libpam-runtime*.deb libpam0g*.deb
rm -rf *.deb *.gz *.dsc *.changes pam-*

# Unfortunately there is no way to automatically remove build deps, so we do this manually.
apt-get remove -y gdebi-core autoconf automake autopoint autotools-dev binutils bsdmainutils \
	build-essential bzip2 cpp cpp-5 debhelper dh-autoreconf dh-strip-nondeterminism \
	diffstat docbook-xml docbook-xsl dpkg-dev flex g++ g++-5 gcc gcc-5 gettext gettext-base \
	groff-base intltool-debian libarchive-zip-perl libasan2 libasprintf0v5 libatomic1 \
	libaudit-dev libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libcrack2 libcrack2-dev libcroco3 \
	libdb-dev libdb5.3-dev libdpkg-perl libfile-stripnondeterminism-perl libfl-dev libgc1c2 \
	libgcc-5-dev libgdbm3 libgomp1 libgpm2 libicu55 libisl15 libitm1 liblsan0 libmpc3 \
	libmpfr4 libmpx0 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libperl5.22 \
	libpipeline1 libquadmath0 libselinux1-dev libsepol1-dev libsigsegv2 libstdc++-5-dev \
	libtimedate-perl libtool libtsan0 libubsan0 libunistring0 libxml2 libxml2-utils \
	libxslt1.1 linux-libc-dev m4 make man-db patch perl perl-modules-5.22 pkg-config \
	po-debconf quilt sgml-base sgml-data w3m xml-core xsltproc xz-utils

apt-get remove -y gdebi-core
apt-get autoremove -y
