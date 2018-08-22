#!/usr/bin/env bash
set -eu



# Authenticate with wp-stateless account to ensure we can pull from SQL bucket
gcloud auth activate-service-account --key-file secrets/service-accounts/${NRO}.json

gsutil cp "gs://${SOURCE_CONTENT_BUCKET}/${SOURCE_CONTENT_SQLDUMP}.gz" . && gunzip -k -f "${SOURCE_CONTENT_SQLDUMP}.gz"

################################################################################

CLOUDSQL_ENV=develop MYSQL_ROOT_PASSWORD=${MYSQL_DEVELOPMENT_ROOT_PASSWORD} create_mysql_user_database.sh

################################################################################

if [[ ${MAKE_RELEASE,,} = "true" ]]
then
  CLOUDSQL_ENV=release MYSQL_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD} create_mysql_user_database.sh
fi

################################################################################
if [[ ${MAKE_MASTER,,} = "true" ]]
then
  CLOUDSQL_ENV=master MYSQL_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD} create_mysql_user_database.sh
fi
