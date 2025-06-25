#!/bin/bash

set -e

# Constants
readonly DFT_LOG_FLR="/var/log/librebooking"
readonly DFT_LOG_LEVEL="none"
readonly DFT_LOG_SQL=false
readonly DFT_LB_ENV="production"
readonly DFT_LB_PATH=""

file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
  local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
  if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
      echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
      exit 1
  fi
  if [ -n "${varValue}" ]; then
      export "$var"="${varValue}"
  elif [ -n "${fileVarValue}" ]; then
      export "$var"="$(cat "${fileVarValue}")"
  elif [ -n "${def}" ]; then
      export "$var"="$def"
  fi
  unset "$fileVar"
}

LB_LOG_FOLDER=${LB_LOG_FOLDER:-${DFT_LOG_FLR}}
LB_LOG_LEVEL=${LB_LOG_LEVEL:-${DFT_LOG_LEVEL}}
LB_LOG_SQL=${LB_LOG_SQL:-${DFT_LOG_SQL}}
LB_ENV=${LB_ENV:-${DFT_LB_ENV}}
LB_PATH=${LB_PATH:-${DFT_LB_PATH}}

LB_DB_USER=${LB_DB_USER:-"librebooking"}
LB_DB_NAME=${LB_DB_NAME:-"librebooking"}
LB_DB_USER_PWD="${LB_DB_USER_PWD:-$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)}"
LB_DB_HOST=${LB_DB_HOST:-"127.0.0.1"}

# No configuration file inside directory /config
if ! [ -f /config/config.php ]; then
  echo "Initialize file config.php"
  cp /var/www/html/config/config.dist.php /config/config.php
  chown www-data:www-data /config/config.php
  sed \
    -i /config/config.php \
    -e "s:\(\['registration.captcha.enabled'\]\) = 'true':\1 = 'false':" \
    -e "s:\(\['database'\]\['user'\]\) = '.*':\1 = '${LB_DB_USER}':" \
    -e "s:\(\['database'\]\['password'\]\) = '.*':\1 = '${LB_DB_USER_PWD}':" \
    -e "s:\(\['database'\]\['name'\]\) = '.*':\1 = '${LB_DB_NAME}':"
fi

# Set the script url
sed \
  -i /config/config.php \
  -e "s#\(\['script.url'\]\)[[:space:]]*=[[:space:]]*'.*';#\1 = '${LB_SCRIPT_URL}';#"

# Set the configuration file database settings
sed \
  -i /config/config.php \
  -e "s:\(\['registration.captcha.enabled'\]\) = 'true':\1 = 'false':" \
  -e "s:\(\['database'\]\['hostspec'\]\) = '.*':\1 = '${LB_DB_HOST}':" \
  -e "s:\(\['database'\]\['user'\]\) = '.*':\1 = '${LB_DB_USER}':" \
  -e "s:\(\['database'\]\['password'\]\) = '.*':\1 = '${LB_DB_USER_PWD}':" \
  -e "s:\(\['database'\]\['name'\]\) = '.*':\1 = '${LB_DB_NAME}':"

# Set secondary configuration settings
sed \
  -i /config/config.php \
  -e "s:\(\['default.timezone'\]\) = '.*':\1 = '${TZ}':" \
  -e "s:\(\['logging'\]\['folder'\]\) = '.*':\1 = '${LB_LOG_FOLDER}':" \
  -e "s:\(\['logging'\]\['level'\]\) = '.*':\1 = '${LB_LOG_LEVEL}':" \
  -e "s:\(\['logging'\]\['sql'\]\) = '.*':\1 = '${LB_LOG_SQL}':"

# Create the plugins configuration file inside the volume
for source in $(find /var/www/html/plugins -type f -name "*dist*"); do
  target=$(echo "${source}" | sed -e "s/.dist//")
  if ! [ -f "/config/$(basename ${target})" ]; then
    cp --no-clobber "${source}" "/config/$(basename ${target})"
    chown www-data:www-data "/config/$(basename ${target})"
  fi
  if ! [ -f ${target} ]; then
    ln -s "/config/$(basename ${target})" "${target}"
  fi
done

# Link the configuration file
if ! [ -f /var/www/html/config/config.php ]; then
  ln -s /config/config.php /var/www/html/config/config.php
fi

# Backup initiated config.php for reset
if ! [ -f /config-backup/config.php ]; then
  echo "Backup config.php file"
  cp /config/config.php /setup/backup/config.php
  chown www-data:www-data /setup/backup/config.php
fi

# Set timezone
if test -f /usr/share/zoneinfo/${TZ}; then
  ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

  INI_FILE="/usr/local/etc/php/conf.d/librebooking.ini"
  echo "[date]" > ${INI_FILE}
  echo "date.timezone=\"${TZ}\"" >> ${INI_FILE}
fi

# Get log directory
log_flr=$(grep \
  -e "\['logging'\]\['folder'\]" \
  /var/www/html/config/config.php \
  | cut -d " " -f3 | cut -d "'" -f2)
log_flr=${log_flr:-${DFT_LOG_FLR}}

# Missing log directory
if ! test -d "${log_flr}"; then
  mkdir -p "${log_flr}"
  chown -R www-data:www-data "${log_flr}"
fi

# Missing log file
if ! test -f "${log_flr}/app.log"; then
  touch "${log_flr}/app.log"
  chown www-data:www-data "${log_flr}/app.log"
fi

# A URL path prefix was set
if ! test -z "${LB_PATH}"; then
  ## Set server document root 1 directory up
  sed \
    -i /etc/apache2/sites-enabled/000-default.conf \
    -e "s:/var/www/html:/var/www:"

  ## Rename the html directory as the URL prefix
  ln -s /var/www/html "/var/www/${LB_PATH}"
  chown www-data:www-data "/var/www/${LB_PATH}"

  ## Adapt the .htaccess file
  sed \
    -i /var/www/${LB_PATH}/.htaccess \
    -e "s:\(RewriteCond .*\)/Web/:\1\.\*/Web/:" \
    -e "s:\(RewriteRule .*\) /Web/:\1 /${LB_PATH}/Web/:"
fi

echo "Starting MariaDB..."
service mariadb start

# Wait for MariaDB to become available
echo "Waiting for MariaDB to be ready..."
for i in {1..10}; do
  if mysqladmin ping --silent; then
    echo "MariaDB is ready."
    break
  fi
  echo "Waiting... ($i)"
  sleep 0.2
done

RESET_MARKER="/setup/.initialized"
RESET_AFTER_SECONDS="${RESET_AFTER_SECONDS:-3600}"

if [ "$LB_RESET_ON_START" = "true" ]; then
  if [ -f "$RESET_MARKER" ]; then
    # Marker exists — check file age
    NOW=$(date +%s)
    FILE_TIME=$(stat -c %Y "$RESET_MARKER")
    AGE=$((NOW - FILE_TIME))

    if [ "$AGE" -ge "${RESET_AFTER_SECONDS}" ]; then
      echo "Reset marker older than 60 minutes ($AGE seconds) — running reset..."
      /usr/local/bin/reset-container.sh
      touch "$RESET_MARKER"
    else
      echo "Reset marker is too recent ($AGE seconds ago) — skipping reset."
    fi
  else
    # First-time setup — mark initialized and reset now
    echo "No reset marker found — initializing and running reset..."
    /setup/init-database.sh
    touch "$RESET_MARKER"
  fi
fi

# Start cron in background
service cron start

echo "#########################################"
echo "#                                       #"
echo "# Use the following login for demo      #"
echo "# user: 'user'  | password: 'demouser'  #"
echo "# user: 'admin' | password: 'demoadmin' #"
echo "#                                       #"
echo "#########################################"

# Run the apache server
exec "$@"
