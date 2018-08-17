#!/usr/bin/env bash
set -eauo pipefail

pw_length=32

if [[ ! -f "secrets/common" ]]
then
  echo "WARNING: File not found: secrets/common"
  echo "Scaffolding common secrets file ..."

  cat <<EOF > secrets/common
# CircleCI token: https://circleci.com/account/api
CIRCLE_TOKEN=
# Github personal access token: https://github.com/settings/tokens
GITHUB_OAUTH_TOKEN=
# Production environment CloudSQL user with all privileges
# https://console.cloud.google.com/sql/instances
MYSQL_PRODUCTION_ROOT_USER=
MYSQL_PRODUCTION_ROOT_PASSWORD=
# Development environment CloudSQL user with all privileges
# https://console.cloud.google.com/sql/instances/p4-develop-k8s/overview?project=planet-4-151612
MYSQL_DEVELOPMENT_ROOT_USER=
MYSQL_DEVELOPMENT_ROOT_PASSWORD=
EOF
  echo "Please edit file 'secrets/common', fill fields as appropriate and re-run ./configure.sh"
  exit 1
else
  . secrets/common
fi

if [[ -f "NRO" ]]
then
  previous_nro=$(cat NRO)
else
  previous_nro=
fi

nro=${1:-$previous_nro}
read -p "Enter NRO Name: [$nro] " this_nro
nro=${this_nro:-$nro}

if [[ -z "${nro}" ]]
then
  echo "ERROR: Must specify a name for the deployment"
  exit 1
fi

echo $nro > NRO

nro_sanitised=$(echo $nro | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')

if [[ -f "secrets/env.${nro_sanitised}" ]]
then
  . secrets/env.${nro_sanitised}
fi

echo
echo "---"
echo
APP_HOSTPATH=${APP_HOSTPATH:-$nro_sanitised}
read -p "APP_HOSTPATH [${APP_HOSTPATH}] " app_hostpath
APP_HOSTPATH=${app_hostpath:-$APP_HOSTPATH}
echo
echo "---"
echo
GITHUB_REPOSITORY_NAME=${GITHUB_REPOSITORY_NAME:-planet4-${nro_sanitised}}
read -p "GITHUB_REPOSITORY_NAME [${GITHUB_REPOSITORY_NAME}] " repo_name
GITHUB_REPOSITORY_NAME=${repo_name:-$GITHUB_REPOSITORY_NAME}
echo
echo "---"
echo
CONTAINER_PREFIX=${CONTAINER_PREFIX:-planet4-${nro_sanitised}}
read -p "CONTAINER_PREFIX [${CONTAINER_PREFIX}] " container_prefix
CONTAINER_PREFIX=${container_prefix:-$CONTAINER_PREFIX}
echo
echo "---"
echo
GITHUB_USER_EMAIL=${GITHUB_USER_EMAIL:-$(git config --global user.email)}
read -p "GITHUB_USER_EMAIL [${GITHUB_USER_EMAIL}] " git_email
GITHUB_USER_EMAIL=${git_email:-$GITHUB_USER_EMAIL}
echo
echo "---"
echo
GITHUB_USER_NAME=${GITHUB_USER_NAME:-$(git config --global user.name)}
read -p "GITHUB_USER_NAME [${GITHUB_USER_NAME}] " git_name
GITHUB_USER_NAME=${git_name:-$GITHUB_USER_NAME}
echo
echo "---"
echo
MAKE_MASTER=${MAKE_MASTER:-true}
read -p "MAKE_MASTER [${MAKE_MASTER}] " make_master
MAKE_MASTER=${make_master:-$MAKE_MASTER}
echo
echo "---"
echo
MAKE_RELEASE=${MAKE_RELEASE:-true}
read -p "MAKE_RELEASE [${MAKE_RELEASE}] " make_release
MAKE_RELEASE=${make_release:-$MAKE_RELEASE}
echo
echo "---"
echo
NEWRELIC_APPNAME=${NEWRELIC_APPNAME:-"P4 ${nro}"}
read -p "NEWRELIC_APPNAME [${NEWRELIC_APPNAME}] " nr_appname
NEWRELIC_APPNAME=${nr_appname:-$NEWRELIC_APPNAME}
echo
echo "---"
echo
MYSQL_USERNAME=${MYSQL_USERNAME:-"planet4-${nro_sanitised}"}
read -p "MYSQL_USERNAME [${MYSQL_USERNAME}] " mysql_user
MYSQL_USERNAME=${mysql_user:-$MYSQL_USERNAME}
echo
echo "---"
echo
MYSQL_PASSWORD=${MYSQL_PASSWORD:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${pw_length};echo;)}
read -p "MYSQL_PASSWORD [${MYSQL_PASSWORD}] " mysql_pass
MYSQL_PASSWORD=${mysql_pass:-$MYSQL_PASSWORD}
echo
echo "---"
echo
echo "Google storage bucket locations: https://cloud.google.com/storage/docs/bucket-locations"
STATELESS_BUCKET_LOCATION=${STATELESS_BUCKET_LOCATION:-us}
read -p "STATELESS_BUCKET_LOCATION [${STATELESS_BUCKET_LOCATION}] " bucket_location
STATELESS_BUCKET_LOCATION=${bucket_location:-$STATELESS_BUCKET_LOCATION}
echo
echo "---"
echo
dockerize --template "env.tmpl:secrets/env.${nro_sanitised}"
cat secrets/env.${nro_sanitised}
echo
echo "---"
echo

if [[ -f "secrets/service-account/${nro_sanitised}.json" ]]
then
  if command -v jq > /dev/null
  then
    echo "$(jq --version) validating: secrets/service-account/${nro_sanitised}.json"
    if ! jq -e . <secrets/service-account/${nro_sanitised}.json
    then
      echo "ERROR reading: secrets/service-account/${nro_sanitised}.json"
      echo "Failed to parse JSON, or got false/null"
      echo
      exit 1
    fi
  else
    "Please install 'jq' to validate json files: https://stedolan.github.io/jq/download/"
  fi
else
  echo "WARNING: File not found: secrets/service-account/${nro_sanitised}.json"
  echo "Please ensure you have a GCP service account JSON file with the following permissions:"
  echo " - SQL Client"
  echo " - Storage Admin"
  echo "For each GCP project in the deployment"
  echo
  echo "---"
  echo
fi

echo "Please confirm configuration looks good and then:"
echo
echo "$ make run"
echo
