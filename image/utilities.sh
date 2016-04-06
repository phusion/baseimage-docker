#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Often used tools.
$minimal_apt_get_install curl less vim-tiny psmisc
ln -s /usr/bin/vim.tiny /usr/bin/vim

## This tool runs a command as another user and sets $HOME.
cp /bd_build/bin/setuser /sbin/setuser

## Replace dangerous upstart commands
rm -f /sbin/init /sbin/telinit /sbin/reboot /sbin/shutdown
cat > /sbin/reboot << EOF
#!/bin/sh
# This file is intentionally changed by huanghao@yy.com
/bin/echo -e "\n*** reboot was called from inside container" >> /dev/termination-log
/bin/kill 1
EOF
ln -s /sbin/reboot /sbin/shutdown
cat > /sbin/init << EOF
#!/bin/sh
# This file is intentionally changed by huanghao@yy.com
>&2 echo init is disabled intentionally.
EOF
ln -s /sbin/init /sbin/telinit
chmod +x /sbin/init /sbin/telinit /sbin/reboot /sbin/shutdown
