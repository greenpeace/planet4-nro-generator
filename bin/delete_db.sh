#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

################################################################################

CLOUDSQL_ENV=develop MYSQL_ROOT_PASSWORD=${MYSQL_DEVELOPMENT_ROOT_PASSWORD} delete_mysql_user_database.sh

################################################################################

CLOUDSQL_ENV=release MYSQL_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD} delete_mysql_user_database.sh

################################################################################

CLOUDSQL_ENV=master MYSQL_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD} delete_mysql_user_database.sh
