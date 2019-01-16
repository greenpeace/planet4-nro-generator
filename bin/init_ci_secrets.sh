#!/usr/bin/env bash
set -eu

if [[ ! -f secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json ]]
then
  echo "ERROR: file not found: secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json"
  echo "Please create service account and download JSON key first:"
  echo " $ bin/create_service_account.sh"
  exit 1
fi

if command -v jq > /dev/null
then
  echo "$(jq --version) validating: secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json"
  if ! jq -e . <"secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json"
  then
    echo "ERROR reading: secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json"
    echo "Failed to parse JSON, or got false/null"
    echo
    exit 1
  fi
else
  "Please install 'jq' to validate json files: https://stedolan.github.io/jq/download/"
fi

json_b64=$(openssl base64 -A <"secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json")

add_ci_env_var.sh WP_STATELESS_KEY "$json_b64"
add_ci_env_var.sh SQLPROXY_KEY "$json_b64"
