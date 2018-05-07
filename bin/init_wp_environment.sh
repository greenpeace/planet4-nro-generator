#!/usr/bin/env bash
set -e

[[ -f secrets/env ]] && source secrets/env



add_environment_variable.sh WP_DB_USERNAME "$(echo "${MYSQL_USERNAME}" | base64 -w 0)" &
add_environment_variable.sh WP_DB_PASSWORD "$(echo "${MYSQL_PASSWORD}" | base64 -w 0)" &
add_environment_variable.sh WP_DB_DATABASE "$(echo "${MYSQL_USERNAME}_${MYSQL_DATABASE}" | base64 -w 0)" &

if \
  [ -z "${WP_AUTH_KEY}" ] || \
  [ -z "${WP_AUTH_SALT}" ] || \
  [ -z "${WP_LOGGED_IN_KEY}" ] || \
  [ -z "${WP_LOGGED_IN_SALT}" ] || \
  [ -z "${WP_NONCE_KEY}" ] || \
  [ -z "${WP_NONCE_SALT}" ] || \
  [ -z "${WP_SECURE_AUTH_KEY}" ] || \
  [ -z "${WP_SECURE_AUTH_SALT}" ]
 then
   echo "Generating Wordpress keys & salts from https://api.wordpress.org/secret-key/1.1/salt/..."
   keys=$(curl --connect-timeout 5 \
       --max-time 10 \
       --retry 5 \
       --retry-max-time 60 \
       https://api.wordpress.org/secret-key/1.1/salt/)

  WP_AUTH_KEY="$(echo "$keys" | sed -rn "s/.*define\('AUTH_KEY',\s+'([^']+).*/\1/p" | base64 -w 0)"
  WP_SECURE_AUTH_KEY="$(echo "$keys" | sed -rn "s/.*define\('SECURE_AUTH_KEY',\s+'([^']+).*/\1/p" | base64 -w 0)"
  WP_LOGGED_IN_KEY="$(echo "$keys" | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p" | base64 -w 0)"
  WP_NONCE_KEY="$(echo "$keys" | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p" | base64 -w 0)"

  WP_AUTH_SALT="$(echo "$keys" | sed -rn "s/.*define\('AUTH_SALT',\s+'([^']+).*/\1/p" | base64 -w 0)"
  WP_SECURE_AUTH_SALT="$(echo "$keys" | sed -rn "s/.*define\('SECURE_AUTH_SALT',\s+'([^']+).*/\1/p" | base64 -w 0)"
  WP_LOGGED_IN_SALT="$(echo "$keys" | sed -rn "s/.*define\('LOGGED_IN_SALT',\s+'([^']+).*/\1/p" | base64 -w 0)"
  WP_NONCE_SALT="$(echo "$keys" | sed -rn "s/.*define\('NONCE_SALT',\s+'([^']+).*/\1/p" | base64 -w 0)"
fi

add_environment_variable.sh WP_AUTH_KEY "${WP_AUTH_KEY}" &
add_environment_variable.sh WP_AUTH_SALT "${WP_AUTH_SALT}" &
add_environment_variable.sh WP_LOGGED_IN_KEY "${WP_LOGGED_IN_KEY}" &
add_environment_variable.sh WP_LOGGED_IN_SALT "${WP_LOGGED_IN_SALT}" &
add_environment_variable.sh WP_NONCE_KEY "${WP_NONCE_KEY}" &
add_environment_variable.sh WP_NONCE_SALT "${WP_NONCE_SALT}" &
add_environment_variable.sh WP_SECURE_AUTH_KEY "${WP_SECURE_AUTH_KEY}" &
add_environment_variable.sh WP_SECURE_AUTH_SALT "${WP_SECURE_AUTH_SALT}" &

wait
