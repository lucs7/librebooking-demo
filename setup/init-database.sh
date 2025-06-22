#!/bin/bash
#Auto-initiate DB
echo "Initiating database"
envsubst < /setup/init.sql  | mysql -u root

#Run upgrades
echo "Running database upgrades"
find "/var/www/html/database_schema/upgrades" -type f -name "*.sql" | sort | while read -r sql_file; do
  mysql -u root "${LB_DB_NAME}" < "$sql_file"
  echo "Running upgrade: $sql_file"
done

echo "Seeding sample data"
mysql -u root "${LB_DB_NAME}" <  "/var/www/html/database_schema/create-data.sql"
mysql -u root "${LB_DB_NAME}"  < "/var/www/html/database_schema/sample-data-utf8.sql"
mysql -u root "${LB_DB_NAME}"  < "/setup/announcements.sql"

echo "Add demo users"
USER_SALT=$(openssl rand -hex 4)
ADMIN_SALT=$(openssl rand -hex 4)
USER_PASS_HASH=$(echo -n "demouser${USER_SALT}" | sha1sum | awk '{print $1}')
ADMIN_PASS_HASH=$(echo -n "demoadmin${ADMIN_SALT}" | sha1sum | awk '{print $1}')

mysql -u root "${LB_DB_NAME}" <<EOF
UPDATE users SET password = '${USER_PASS_HASH}', salt = '${USER_SALT}' WHERE username = 'user';
UPDATE users SET password = '${ADMIN_PASS_HASH}', salt = '${ADMIN_SALT}' WHERE username = 'admin';
EOF

echo "Dumping initialized database to /setup/backup/librebooking.sql"
mysqldump --add-drop-table -u root "${LB_DB_NAME}" > /setup/backup/librebooking.sql