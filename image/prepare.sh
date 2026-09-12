#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Prevent initramfs updates from trying to run grub and lilo.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189
export INITRD=no
mkdir -p /etc/container_environment
echo -n no > /etc/container_environment/INITRD

## Enable Ubuntu Universe, Multiverse, and deb-src for main.
if grep -E '^ID=' /etc/os-release | grep -q ubuntu; then
  UBUNTU_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
  # Ubuntu 24.04+ uses DEB822 format (.sources files); older releases use sources.list
  if dpkg --compare-versions "$UBUNTU_VERSION" ge "24.04" 2>/dev/null && \
      compgen -G '/etc/apt/sources.list.d/*.sources' > /dev/null; then
    # DEB822 format: enable universe and multiverse components
    for f in /etc/apt/sources.list.d/*.sources; do
      sed -i 's/^Components: main$/Components: main restricted universe multiverse/' "$f"
      sed -i 's/^Components: main restricted$/Components: main restricted universe multiverse/' "$f"
    done
  else
    # Legacy sources.list format (Ubuntu < 24.04)
    sed -i 's/^#\s*\(deb.*main restricted\)$/\1/g' /etc/apt/sources.list
    sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
    sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list
  fi
fi

apt-get update

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

# apt-utils fix for Ubuntu 16.04
$minimal_apt_get_install apt-utils

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https ca-certificates

## Install add-apt-repository
if grep -E '^ID=' /etc/os-release | grep -q ubuntu; then
  $minimal_apt_get_install software-properties-common
fi

## Install python3 for debian
  $minimal_apt_get_install python3

## Upgrade all packages.
apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"

## Ubuntu 26.04+ ships uutils-coreutils (Rust) by default.
## Optionally replace them with GNU Coreutils when
## INSTALL_GNU_COREUTILS=1 is set at build time.
if grep -E '^ID=' /etc/os-release | grep -q ubuntu; then
  UBUNTU_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
  if dpkg --compare-versions "$UBUNTU_VERSION" ge "26.04" 2>/dev/null; then
    case "${INSTALL_GNU_COREUTILS:-0}" in
      0|1)
        INSTALL_GNU_COREUTILS_NORMALIZED="${INSTALL_GNU_COREUTILS:-0}"
        ;;
      *)
        echo "*** Invalid value for INSTALL_GNU_COREUTILS: '${INSTALL_GNU_COREUTILS}'" >&2
        echo "*** Expected 0 or 1." >&2
        exit 1
        ;;
    esac
    if [ "$INSTALL_GNU_COREUTILS_NORMALIZED" = "1" ]; then
      echo "*** Removing Rust to restore GNU Coreutils..."
      # GNU Coreutils can only be installed by removing `coreutils-from-uutils`
      apt-get remove -y --allow-remove-essential coreutils-from-uutils
      # Verify that GNU coreutils are now the active implementation on PATH.
      # Some packages may install binaries under a non-default path and rely on
      # update-alternatives; if so the replacement has not taken effect.
      if ! ls --version 2>&1 | grep -qi 'gnu coreutils'; then
        echo "*** ERROR: coreutils-from-gnu was installed but GNU coreutils are not active on PATH." >&2
        echo "*** 'ls --version' does not report 'GNU coreutils'." >&2
        echo "*** The package may place binaries outside the default PATH or require" >&2
        echo "*** manual update-alternatives configuration. Check Ubuntu 26.04 packaging." >&2
        exit 1
      fi
      LS_VER=$(ls --version | head -1)
      echo "*** GNU Coreutils are active ($LS_VER)."
    else
      echo "*** Ubuntu 26.04 detected: using default uutils-coreutils (Rust)."
      echo "*** Set INSTALL_GNU_COREUTILS=1 at build time to use GNU Coreutils instead."
    fi
  fi
fi

## Fix locale.
case $(grep '^ID=' /etc/os-release | cut -d= -f2) in
  ubuntu)
    $minimal_apt_get_install language-pack-en
    ;;
  debian)
    $minimal_apt_get_install locales locales-all
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    ;;
  *)
    ;;
esac
locale-gen en_US
update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
echo -n en_US.UTF-8 > /etc/container_environment/LANG
echo -n en_US.UTF-8 > /etc/container_environment/LC_CTYPE
