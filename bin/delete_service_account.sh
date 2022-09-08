#!/usr/bin/env bash
set -ux

nro=${1:-${NRO}}
service_account_name=$nro@${GCP_DEVELOPMENT_PROJECT}.iam.gserviceaccount.com

gcloud projects remove-iam-policy-binding "$GCP_DEVELOPMENT_PROJECT" \
  --member="serviceAccount:$service_account_name" \
  --role roles/cloudsql.client

gcloud projects remove-iam-policy-binding "$GCP_PRODUCTION_PROJECT" \
  --member="serviceAccount:$service_account_name" \
  --role roles/cloudsql.client

# Delete service account
gcloud config set project "$GCP_DEVELOPMENT_PROJECT"

gcloud iam service-accounts delete "$service_account_name"

gcloud iam service-accounts list

if [[ -f "secrets/service-accounts/$nro.json" ]]; then
  rm -f "secrets/service-accounts/$nro.json"
fi
