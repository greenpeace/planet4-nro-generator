#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

cloud_sql_proxy "-instances=${CLOUDSQL_INSTANCE}=tcp:3306" \
                 -credential_file=secrets/cloudsql-service-account.json &

gcloud auth activate-service-account --key-file secrets/stateless-service-account.json

gsutil cp "gs://${CONTENT_BUCKET}/${CONTENT_SQLDUMP}.gz" .
gunzip -k -f "${CONTENT_SQLDUMP}.gz"

dockerize \
  -template templates/create_user.sql.tmpl:./create_user.sql \
  -wait tcp://127.0.0.1:3306 \
  -timeout 30s

cat create_user.sql

echo "Creating user '${MYSQL_USERNAME}' and database '${MYSQL_USERNAME}_${MYSQL_DATABASE}' ..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -h 127.0.0.1  < create_user.sql

echo "Importing database from: gs://${CONTENT_BUCKET}/${CONTENT_SQLDUMP}.gz ..."
mysql -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" -h 127.0.0.1 "${MYSQL_USERNAME}_${MYSQL_DATABASE}" < "${CONTENT_SQLDUMP}"

kill $(jobs -p)
