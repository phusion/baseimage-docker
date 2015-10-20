#!/bin/sh
set -e

# If /dev/log is either a named pipe or it was placed there accidentally,
# e.g. because of the issue documented at https://github.com/phusion/baseimage-docker/pull/25,
# then we remove it.
if [ ! -S /dev/log ]; then rm -f /dev/log; fi
if [ ! -S /var/lib/syslog-ng/syslog-ng.ctl ]; then rm -f /var/lib/syslog-ng/syslog-ng.ctl; fi

SYSLOGNG_OPTS=""

[ -r /etc/default/syslog-ng ] && . /etc/default/syslog-ng

case "x$CONSOLE_LOG_LEVEL" in
  x[1-8])
    dmesg -n $CONSOLE_LOG_LEVEL
    ;;
  x)
    ;;
  *)
    echo "CONSOLE_LOG_LEVEL is of unaccepted value."
    ;;
esac

if [ ! -e /dev/xconsole ]
then
  mknod -m 640 /dev/xconsole p
  chown root:adm /dev/xconsole
  [ -x /sbin/restorecon ] && /sbin/restorecon $XCONSOLE
fi

exec syslog-ng -F -p /var/run/syslog-ng.pid $SYSLOGNG_OPTS
