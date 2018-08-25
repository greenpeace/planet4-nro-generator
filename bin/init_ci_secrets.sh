#!/usr/bin/env bash
set -eu

nro_sanitised=${1:-$NRO}

if [[ ! -f secrets/service-accounts/${nro_sanitised}.json ]]
then
  echo "ERROR: file not found: secrets/service-accounts/${nro_sanitised}.json"
  echo "Please create service account and download JSON key first:"
  echo " $ bin/create_service_account.sh"
  exit 1
fi

if command -v jq > /dev/null
then
  echo "$(jq --version) validating: secrets/service-accounts/${nro_sanitised}.json"
  if ! jq -e . <secrets/service-accounts/${nro_sanitised}.json
  then
    echo "ERROR reading: secrets/service-accounts/${nro_sanitised}.json"
    echo "Failed to parse JSON, or got false/null"
    echo
    exit 1
  fi
else
  "Please install 'jq' to validate json files: https://stedolan.github.io/jq/download/"
fi

json_b64=$(cat secrets/service-accounts/${nro_sanitised}.json | openssl base64 -A)

add_ci_env_var.sh WP_STATELESS_KEY "$json_b64"
add_ci_env_var.sh SQLPROXY_KEY "$json_b64"
