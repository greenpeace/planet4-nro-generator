#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

db=${MYSQL_USERNAME}_${MYSQL_DATABASE}_${CLOUDSQL_ENV}

echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "WARNING: YOU ARE ABOUT TO DELETE MYSQL USERS AND DATABASES"
echo ""
if [[ ${CLOUDSQL_ENV} = "develop" ]]
then
  echo "Instance: ${GCP_DEVELOPMENT_PROJECT}:${GCP_DEVELOPMENT_REGION}:${GCP_DEVELOPMENT_CLOUDSQL}"
else
  echo "Instance: ${GCP_PRODUCTION_PROJECT}:${GCP_PRODUCTION_REGION}:${GCP_PRODUCTION_CLOUDSQL}"
fi
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""

echo "User:     ${MYSQL_USERNAME}"
echo "Database: ${db}"
echo ""
echo "This can not be undone!"
echo ""
read -p "Are you sure? [y/N] " yn
case $yn in
    [Yy]* ) : ;;
    * ) exit;;
esac

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
 -template "templates/delete_user.sql.tmpl:./delete_${CLOUDSQL_ENV}_user.sql" \
 -template "templates/delete_database.sql.tmpl:./delete_${CLOUDSQL_ENV}_database.sql" \
 -wait tcp://127.0.0.1:3306 \
 -timeout 30s > /dev/null 2>&1

echo "---------"
echo ""
echo "User     '${MYSQL_USERNAME}'..."
echo ""
cat "delete_${CLOUDSQL_ENV}_user.sql"
echo ""
mysql -v --defaults-extra-file="mysql_${CLOUDSQL_ENV}.cnf"  < "delete_${CLOUDSQL_ENV}_user.sql"

echo "---------"
echo ""
echo "Database '${db}' "
echo ""
cat "delete_${CLOUDSQL_ENV}_database.sql"
echo ""
mysql -v --defaults-extra-file="mysql_${CLOUDSQL_ENV}.cnf"  < "delete_${CLOUDSQL_ENV}_database.sql"
echo "---------"
echo ""
 # Stop background jobs
kill "$(jobs -p)"
