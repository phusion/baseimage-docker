#!/bin/sh -e

MY_CRON_PREFIX="/etc/my_cron."
CRON_PREFIX="/etc/cron."
CRONS="d hourly daily weekly monthly"

echo "Adding custom cron jobs"
for CRON in $CRONS; do
    DIR="${MY_CRON_PREFIX}$CRON/*"
    for MY_CRON in $(ls $DIR 2>/dev/null); do
        NEW_CRON=${CRON_PREFIX}$CRON/$(basename $MY_CRON)
        echo "  $MY_CRON"
        # Use cat instead of cp to avoid symlinks, weird permissions, etc
        cat $MY_CRON > $NEW_CRON
    done
done

echo "Setting cronjob permissions"
for CRON in $CRONS; do
    DIR="${CRON_PREFIX}$CRON"
    if [ "$CRON" = "d" ]; then
        chmod 0644 -R $DIR
    else
        chmod 0755 -R $DIR
    fi
    chown root:root -R $DIR
done
