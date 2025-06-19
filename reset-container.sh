#!/bin/bash
echo "Restoring /config from /config-backup at $(date)" >> /var/log/cron.log
rm -rf /config/*
cp -r /config-backup/* /config/
chown -R www-data:www-data /config

echo "Resetting database at $(date)" >> /var/log/cron.log
mysql -u root < /usr/local/bin/init.sql