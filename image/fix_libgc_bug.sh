#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

# Fixes https://github.com/docker/docker/issues/6345
# The Github is closed, but some apps such as pbuilder still triggers it.

export CONFIGURE_OPTS=--disable-audit
cd /tmp

$minimal_apt_get_install gdebi-core
apt-get build-dep -y --no-install-recommends libgc
apt-get source -y libgc
echo "#define NO_GETCONTEXT" >> libgc-7.4.2/include/private/gcconfig.h
pushd libgc-7.4.2
dpkg-buildpackage -b
popd
gdebi -n libgc1c2_7.4.2-7.3ubuntu0.1_i386.deb
rm -rf *.deb *.gz *.dsc *.changes libgc-*

# Unfortunately there is no way to automatically remove build deps, so we do this manually.
apt-get remove -y gdebi-core autoconf automake autopoint autotools-dev binutils bsdmainutils \
	build-essential bzip2 cpp cpp-5 debhelper dh-autoreconf dh-strip-nondeterminism \
	diffstat dpkg-dev g++ g++-5 gcc gcc-5 gettext gettext-base groff-base hardening-includes \
	intltool-debian libapt-pkg-perl libarchive-zip-perl libasan2 libasprintf0v5 libatomic-ops-dev \
	libatomic1 libc-dev-bin libc6-dev libcc1-0 libcgi-pm-perl libcilkrts5 libclass-accessor-perl \
	libclone-perl libcroco3 libdata-alias-perl libdigest-hmac-perl libdpkg-perl libemail-valid-perl \
	libexporter-tiny-perl libfile-basedir-perl libfile-stripnondeterminism-perl libgcc-5-dev libgdbm3 \
	libgomp1 libhtml-parser-perl libhtml-tagset-perl libicu55 libio-pty-perl libio-socket-inet6-perl \
	libio-socket-ssl-perl libio-string-perl libipc-run-perl libipc-system-simple-perl libisl15 \
	libitm1 liblist-moreutils-perl liblocale-gettext-perl libmailtools-perl libmpc3 libmpfr4 libmpx0 \
	libnet-dns-perl libnet-domain-tld-perl libnet-ip-perl libnet-smtp-ssl-perl libnet-ssleay-perl \
	libparse-debianchangelog-perl libperl5.22 libpipeline1 libquadmath0 libsigsegv2 libsocket6-perl \
	libstdc++-5-dev libsub-name-perl libtext-levenshtein-perl libtimedate-perl libtool libubsan0 \
	libunistring0 liburi-perl libxml2 libyaml-libyaml-perl lintian linux-libc-dev m4 make man-db \
	netbase patch patchutils perl perl-modules-5.22 pkg-config pkg-kde-tools po-debconf t1utils \
	xz-utils

apt-get remove -y gdebi-core
apt-get autoremove -y
