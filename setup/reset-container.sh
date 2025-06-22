#!/bin/bash
set -e

RESET_MARKER="/setup/.initialized"
RESET_AFTER_SECONDS="${RESET_AFTER_SECONDS:-3600}"

echo "Checking reset age at $(date)" >> /var/log/cron.log

if [ -f "$RESET_MARKER" ]; then
  NOW=$(date +%s)
  FILE_TIME=$(stat -c %Y "$RESET_MARKER")
  AGE=$((NOW - FILE_TIME))

  if [ "$AGE" -lt "$RESET_AFTER_SECONDS" ]; then
    echo "Reset skipped — last reset was $AGE seconds ago." >> /var/log/cron.log
    exit 0
  fi
  echo "Reset triggered — last reset was $AGE seconds ago." >> /var/log/cron.log
else
  echo "Reset marker not found — initializing for the first time." >> /var/log/cron.log
fi

echo "Restoring /config/config.php from /setup/backup/config.php" >> /var/log/cron.log
cp /setup/backup/config.php /config/config.php
chown www-data:www-data /config/config.php

echo "Restoring database from /setup/backup/librebooking.sql" >> /var/log/cron.log
mysql -u root "$LB_DB_NAME" < /setup/backup/librebooking.sql

# Update marker timestamp
touch "$RESET_MARKER"
echo "Reset completed at $(date)" >> /var/log/cron.log