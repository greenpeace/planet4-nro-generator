#!/usr/bin/env bash
set -eauo pipefail

pw_length=32

read_properties()
{
  file="$1"
  while IFS="=" read -r key value; do
    case "$key" in
      '') : ;;
      '#'*) : ;;
      *) eval "$key=\"$value\""
    esac
  done < "$file"
}

if [[ ! -f "secrets/common" ]]
then
  echo "Creating file: secrets/common ..."
  echo
  echo "---"
  echo
  echo "CircleCI token: https://circleci.com/account/api"
  read -sp "CIRCLE_TOKEN " CIRCLE_TOKEN
  echo
  echo "---"
  echo
  echo "Github personal access token: https://github.com/settings/tokens"
  read -sp "GITHUB_OAUTH_TOKEN " GITHUB_OAUTH_TOKEN
  echo
  echo "---"
  echo
  echo "Production environment CloudSQL user with all privileges: https://console.cloud.google.com/sql/instances"
  read -p "MYSQL_PRODUCTION_ROOT_USER [root] " prod_root_user
  MYSQL_PRODUCTION_ROOT_USER=${prod_root_user:-root}
  read -sp "MYSQL_PRODUCTION_ROOT_PASSWORD " MYSQL_PRODUCTION_ROOT_PASSWORD
  echo
  echo "---"
  echo
  echo "Development environment CloudSQL user with all privileges: https://console.cloud.google.com/sql/instances"
  read -p "MYSQL_DEVELOPMENT_ROOT_USER [root] " dev_root_user
  MYSQL_DEVELOPMENT_ROOT_USER=${dev_root_user:-root}
  read -sp "MYSQL_DEVELOPMENT_ROOT_PASSWORD " MYSQL_DEVELOPMENT_ROOT_PASSWORD
  echo
  echo "---"

  cat <<EOF > secrets/common
# CircleCI token: https://circleci.com/account/api
CIRCLE_TOKEN=$CIRCLE_TOKEN

# Github personal access token: https://github.com/settings/tokens
GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN

# Development environment CloudSQL user with all privileges
# https://console.cloud.google.com/sql/instances/p4-develop-k8s/overview?project=planet-4-151612
MYSQL_DEVELOPMENT_ROOT_USER=${MYSQL_DEVELOPMENT_ROOT_USER}
MYSQL_DEVELOPMENT_ROOT_PASSWORD=${MYSQL_DEVELOPMENT_ROOT_PASSWORD}

# Production environment CloudSQL user with all privileges
# https://console.cloud.google.com/sql/instances
MYSQL_PRODUCTION_ROOT_USER=${MYSQL_PRODUCTION_ROOT_USER}
MYSQL_PRODUCTION_ROOT_PASSWORD=${MYSQL_PRODUCTION_ROOT_PASSWORD}

EOF
  echo
  echo "Secrets file written to 'secrets/common'"
  echo "Please ensure values are accurate."
  echo
fi

read_properties secrets/common

if [[ -f "NRO" ]]
then
  previous_nro=$(cat NRO)
else
  previous_nro=
fi

echo "---"
echo
nro=${1:-$previous_nro}
read -p "Enter NRO display name, eg: 'Netherlands' [$nro] " this_nro
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
  read_properties secrets/env.${nro_sanitised}
fi

echo
echo "---"
echo
APP_HOSTPATH=${APP_HOSTPATH-$nro_sanitised}
read -p "APP_HOSTPATH [${APP_HOSTPATH}] " app_hostpath
APP_HOSTPATH=${app_hostpath-$APP_HOSTPATH}
echo
GITHUB_REPOSITORY_NAME=${GITHUB_REPOSITORY_NAME:-planet4-${nro_sanitised}}
read -p "GITHUB_REPOSITORY_NAME [${GITHUB_REPOSITORY_NAME}] " repo_name
GITHUB_REPOSITORY_NAME=${repo_name:-$GITHUB_REPOSITORY_NAME}
echo
CONTAINER_PREFIX=${CONTAINER_PREFIX:-planet4-${nro_sanitised}}
read -p "CONTAINER_PREFIX [${CONTAINER_PREFIX}] " container_prefix
CONTAINER_PREFIX=${container_prefix:-$CONTAINER_PREFIX}
echo
GITHUB_USER_EMAIL=${GITHUB_USER_EMAIL:-$(git config --global user.email || true)}
read -p "GITHUB_USER_EMAIL [${GITHUB_USER_EMAIL}] " git_email
GITHUB_USER_EMAIL=${git_email:-$GITHUB_USER_EMAIL}
echo
GITHUB_USER_NAME=${GITHUB_USER_NAME:-$(git config --global user.name || true)}
read -p "GITHUB_USER_NAME [${GITHUB_USER_NAME}] " git_name
GITHUB_USER_NAME=${git_name:-$GITHUB_USER_NAME}
echo
MAKE_DEVELOP=${MAKE_DEVELOP:-true}
read -p "MAKE_DEVELOP [${MAKE_DEVELOP}] " make_develop
MAKE_DEVELOP=${make_develop:-$MAKE_DEVELOP}
echo
MAKE_RELEASE=${MAKE_RELEASE:-true}
read -p "MAKE_RELEASE [${MAKE_RELEASE}] " make_release
MAKE_RELEASE=${make_release:-$MAKE_RELEASE}
echo
MAKE_MASTER=${MAKE_MASTER:-true}
read -p "MAKE_MASTER [${MAKE_MASTER}] " make_master
MAKE_MASTER=${make_master:-$MAKE_MASTER}
echo
NEWRELIC_APPNAME=${NEWRELIC_APPNAME:-"P4 ${nro}"}
read -p "NEWRELIC_APPNAME [${NEWRELIC_APPNAME}] " nr_appname
NEWRELIC_APPNAME=${nr_appname:-$NEWRELIC_APPNAME}
echo
echo "---"
echo
MYSQL_USERNAME=${MYSQL_USERNAME:-"planet4-${${nro_sanitised:0:8}%-}"}
read -p "MYSQL_USERNAME [${MYSQL_USERNAME}] " mysql_user
MYSQL_USERNAME=${mysql_user:-$MYSQL_USERNAME}
echo
MYSQL_PASSWORD=${MYSQL_PASSWORD:-$(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${pw_length};echo;)}
read -p "MYSQL_PASSWORD [${MYSQL_PASSWORD}] " mysql_pass
MYSQL_PASSWORD=${mysql_pass:-$MYSQL_PASSWORD}
echo
echo "Google storage bucket locations: https://cloud.google.com/storage/docs/bucket-locations"
STATELESS_BUCKET_LOCATION=${STATELESS_BUCKET_LOCATION:-us}
read -p "STATELESS_BUCKET_LOCATION [${STATELESS_BUCKET_LOCATION}] " bucket_location
STATELESS_BUCKET_LOCATION=${bucket_location:-$STATELESS_BUCKET_LOCATION}
echo
dockerize --template "env.tmpl:secrets/env.${nro_sanitised}"
cat secrets/env.${nro_sanitised}
echo
echo "---"
echo

service_account_name=$nro_sanitised

# Google Service Account names cannot be less than 6 characters
if [[ ${#service_account_name} -lt 6 ]]
then
  # So append -p4 to the end of the name
  service_account_name=${nro_sanitised}-p4
fi

echo "Service account name: ${service_account_name}"
echo $service_account_name > SERVICE_ACCOUNT_NAME

if [[ ! -f "secrets/service-accounts/${service_account_name}.json" ]]
then
  GCP_DEVELOPMENT_PROJECT=${GCP_DEVELOPMENT_PROJECT:-planet-4-151612} \
  GCP_PRODUCTION_PROJECT=${GCP_PRODUCTION_PROJECT:-planet4-production} \
  bin/init_service_account.sh "$service_account_name" "$nro"
fi

if command -v jq > /dev/null
then
  echo "$(jq --version) validating: secrets/service-accounts/${service_account_name}.json"
  if ! jq -e . <secrets/service-accounts/${service_account_name}.json
  then
    echo "ERROR reading: secrets/service-accounts/${service_account_name}.json"
    echo "Failed to parse JSON, or got false/null"
    echo
    exit 1
  fi
else
  "Please install 'jq' to validate json files: https://stedolan.github.io/jq/download/"
fi

echo "Please confirm configuration looks good and then:"
echo
echo "$ make run"
echo
