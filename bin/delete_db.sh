#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

echo ""
echo "YOU ARE ABOUT TO DELETE FROM HOST ${CLOUDSQL_INSTANCE}"
echo "User:     ${MYSQL_USERNAME}"
echo "Database: ${MYSQL_USERNAME}_${MYSQL_DATABASE}"
echo ""

read -p "Are you sure? [y/N] " yn
case $yn in
    [Yy]* ) : ;;
    * ) exit;;
esac

cloud_sql_proxy "-instances=${CLOUDSQL_INSTANCE}=tcp:3306" \
                 -credential_file=secrets/cloudsql-service-account.json &

dockerize \
  -template templates/delete_database.sql.tmpl:delete_database.sql \
  -template templates/delete_user.sql.tmpl:delete_user.sql \
  -wait tcp://127.0.0.1:3306 \
  -timeout 30s

cat delete_database.sql
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -h 127.0.0.1 < delete_database.sql

cat delete_user.sql
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -h 127.0.0.1 < delete_user.sql

kill $(jobs -p)
