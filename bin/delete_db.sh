#!/usr/bin/env bash
set -eu

################################################################################

CLOUDSQL_ENV=develop MYSQL_ROOT_PASSWORD=${MYSQL_DEVELOPMENT_ROOT_PASSWORD} delete_mysql_user_database.sh

################################################################################

if [[ ${MAKE_RELEASE,,} = "true" ]]
then
  CLOUDSQL_ENV=release MYSQL_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD} delete_mysql_user_database.sh
fi

################################################################################

if [[ ${MAKE_MASTER,,} = "true" ]]
then
  CLOUDSQL_ENV=master MYSQL_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD} delete_mysql_user_database.sh
fi
