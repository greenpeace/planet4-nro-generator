#!/usr/bin/env bash


keys=$(curl --connect-timeout 5 \
    --max-time 10 \
    --retry 5 \
    --retry-max-time 60 \
    https://api.wordpress.org/secret-key/1.1/salt/)

WP_AUTH_KEY="$(echo "$keys" | sed -rn "s/.*define\('AUTH_KEY',\s+'([^']+).*/\1/p")"
WP_SECURE_AUTH_KEY="$(echo "$keys" | sed -rn "s/.*define\('SECURE_AUTH_KEY',\s+'([^']+).*/\1/p")"
WP_LOGGED_IN_KEY="$(echo "$keys" | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p")"
WP_NONCE_KEY="$(echo "$keys" | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p")"

WP_AUTH_SALT="$(echo "$keys" | sed -rn "s/.*define\('AUTH_SALT',\s+'([^']+).*/\1/p")"
WP_SECURE_AUTH_SALT="$(echo "$keys" | sed -rn "s/.*define\('SECURE_AUTH_SALT',\s+'([^']+).*/\1/p")"
WP_LOGGED_IN_SALT="$(echo "$keys" | sed -rn "s/.*define\('LOGGED_IN_SALT',\s+'([^']+).*/\1/p")"
WP_NONCE_SALT="$(echo "$keys" | sed -rn "s/.*define\('NONCE_SALT',\s+'([^']+).*/\1/p")"

echo "WP_AUTH_KEY: $(echo $WP_AUTH_KEY | base64 -w 0)"
echo "WP_AUTH_SALT: $(echo $WP_AUTH_SALT | base64 -w 0)"
echo "WP_LOGGED_IN_KEY: $(echo $WP_LOGGED_IN_KEY | base64 -w 0)"
echo "WP_LOGGED_IN_SALT: $(echo $WP_LOGGED_IN_SALT | base64 -w 0)"
echo "WP_NONCE_KEY: $(echo $WP_NONCE_KEY | base64 -w 0)"
echo "WP_NONCE_SALT: $(echo $WP_NONCE_SALT | base64 -w 0)"
echo "WP_SECURE_AUTH_KEY: $(echo $WP_SECURE_AUTH_KEY | base64 -w 0)"
echo "WP_SECURE_AUTH_SALT: $(echo $WP_SECURE_AUTH_SALT | base64 -w 0)"
