#!/usr/bin/env bash
set -u

name=${1:-${NRO}}

[[ -z "${name:-}" ]] && echo "Usage: $(basename "$0") <service-account-name>" && exit 1

if [[ ! -d "secrets/service-accounts" ]]
then
  echo "ERROR: directory not found: ${PWD}/secrets/service-accounts"
  exit 1
fi

display_name="${2:-$name}"

service_account=$name@${GCP_DEVELOPMENT_PROJECT}.iam.gserviceaccount.com

set -x

gcloud config set project "${GCP_DEVELOPMENT_PROJECT}"

gcloud iam service-accounts create "$name" --display-name "$display_name"

gcloud iam service-accounts describe "$service_account" --format=json

gcloud projects add-iam-policy-binding "${GCP_DEVELOPMENT_PROJECT}" \
  --member="serviceAccount:$service_account" \
--role roles/storage.admin

gcloud projects add-iam-policy-binding "${GCP_DEVELOPMENT_PROJECT}" \
  --member="serviceAccount:$service_account" \
--role roles/cloudsql.client

gcloud projects add-iam-policy-binding "${GCP_PRODUCTION_PROJECT}" \
  --member="serviceAccount:$service_account" \
--role roles/storage.admin

gcloud projects add-iam-policy-binding "${GCP_PRODUCTION_PROJECT}" \
  --member="serviceAccount:$service_account" \
--role roles/cloudsql.client

gcloud iam service-accounts keys list --iam-account="$service_account" --format=json

bin/create_service_account_key.sh "$name" "${GCP_DEVELOPMENT_PROJECT}"
