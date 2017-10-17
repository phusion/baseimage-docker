#!/bin/bash -e

MY_CRON_PREFIX="/etc/my_cron."
CRON_PREFIX="/etc/cron."
CRONS="d hourly daily weekly monthly"

echo "Adding custom cron jobs"
for CRON in $CRONS; do
    DIR="${MY_CRON_PREFIX}$CRON/*"
    for MY_CRON in $(ls $DIR 2>/dev/null); do

        echo "  $MY_CRON"

        CRON_BASENAME=$(basename "$MY_CRON")

        if [ "$CRON" = "d" ]; then
            CRON_FILENAME="$CRON_BASENAME"
        else
            # Only the chars [a-zA-Z0-9_-] are allowed in these crons
            # or they will be siliently ignored by run-parts
            CRON_FILENAME=$(sed 's/[^a-zA-Z0-9_-]/-/g' <<<"$CRON_BASENAME")
        fi

        NEW_CRON=${CRON_PREFIX}$CRON/$CRON_FILENAME

        if [ -f "$NEW_CRON" ] && [ "$CRON_FILENAME" != "$CRON_BASENAME" ]; then
            echo "Warning, your cron job '$CRON_BASENAME' was renamed to '$CRON_FILENAME' for compatibility, but it has overwritten an existing cronjob at $NEW_CRON" >&2
        fi

        # Use cat instead of cp to avoid symlinks, weird permissions, etc
        cat $MY_CRON > $NEW_CRON

        if [ "$CRON" = "d" ]; then
            chmod 0644 "$NEW_CRON"
        else
            chmod 0755 "$NEW_CRON"
        fi
        chown root:root "$NEW_CRON"
    done
done
