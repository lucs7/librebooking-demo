SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

CREATE DATABASE IF NOT EXISTS ${LB_DB_NAME};
CREATE USER IF NOT EXISTS '${LB_DB_USER}'@'%' IDENTIFIED BY '${LB_DB_USER_PWD}';
GRANT ALL PRIVILEGES ON ${LB_DB_USER}.* TO '${LB_DB_NAME}'@'%';
FLUSH PRIVILEGES;
USE ${LB_DB_NAME};

source  /var/www/html/database_schema/create-schema.sql;
