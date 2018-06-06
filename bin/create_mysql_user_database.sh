#!/usr/bin/env bash
set -eu

db=${MYSQL_USERNAME}_${MYSQL_DATABASE}_${CLOUDSQL_ENV}

echo "Creating ${CLOUDSQL_ENV} CloudSQL resources..."
echo ""
echo "Instance:  ${GCP_PRODUCTION_PROJECT}:${GCP_PRODUCTION_REGION}:${GCP_PRODUCTION_CLOUDSQL}"
echo ""
if [[ ${CLOUDSQL_ENV} = "develop" ]]
then
  rootUsername=${MYSQL_DEVELOPMENT_ROOT_USER}
  rootPassword=${MYSQL_DEVELOPMENT_ROOT_PASSWORD}
  # Start SQL proxy in background
  cloud_sql_proxy --quiet "-instances=${GCP_DEVELOPMENT_PROJECT}:${GCP_DEVELOPMENT_REGION}:${GCP_DEVELOPMENT_CLOUDSQL}=tcp:3306" \
                   -credential_file=secrets/cloudsql-service-account.json &
else
  rootUsername=${MYSQL_PRODUCTION_ROOT_USER}
  rootPassword=${MYSQL_PRODUCTION_ROOT_PASSWORD}
  # Start SQL proxy in background
  cloud_sql_proxy --quiet "-instances=${GCP_PRODUCTION_PROJECT}:${GCP_PRODUCTION_REGION}:${GCP_PRODUCTION_CLOUDSQL}=tcp:3306" \
                   -credential_file=secrets/cloudsql-service-account.json &
fi

# Generate files from template, and wait until TCP port is open
MYSQL_DATABASE=${db} \
MYSQL_ROOT_USERNAME=${rootUsername} \
MYSQL_ROOT_PASSWORD=${rootPassword} \
dockerize \
 -template "templates/mysql.cnf.tmpl:./mysql_${CLOUDSQL_ENV}.cnf" \
 -template "templates/create_user.sql.tmpl:./create_${CLOUDSQL_ENV}_user.sql" \
 -template "templates/create_database.sql.tmpl:./create_${CLOUDSQL_ENV}_database.sql" \
 -wait tcp://127.0.0.1:3306 \
 -timeout 30s > /dev/null 2>&1

echo ""
echo "---------"
echo ""
echo "User     '${MYSQL_USERNAME}'..."
echo ""
cat "create_${CLOUDSQL_ENV}_user.sql"
echo ""
mysql -v --defaults-extra-file="mysql_${CLOUDSQL_ENV}.cnf"  < "create_${CLOUDSQL_ENV}_user.sql"

echo "---------"
echo ""
echo "Database '${db}' "
echo ""
cat "create_${CLOUDSQL_ENV}_database.sql"
echo ""
mysql -v --defaults-extra-file="mysql_${CLOUDSQL_ENV}.cnf"  < "create_${CLOUDSQL_ENV}_database.sql"

echo "---------"
echo ""
echo "SQL      gs://${SOURCE_CONTENT_BUCKET}/${SOURCE_CONTENT_SQLDUMP}.gz"
echo ""
head -n 5 "${SOURCE_CONTENT_SQLDUMP}"
echo ""
mysql -v --defaults-extra-file="mysql_${CLOUDSQL_ENV}.cnf" "${db}" < "${SOURCE_CONTENT_SQLDUMP}"
echo "---------"
echo ""
# Stop background jobs
kill "$(jobs -p)"
