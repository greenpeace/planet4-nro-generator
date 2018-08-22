#!/usr/bin/env bash
set -eu

name=${1:-${NRO}}

[[ -z "${name:-}" ]] && echo "Usage: $(basename $0) <service-account-name>" && exit 1

if [[ ! -d "secrets/service-accounts" ]]
then
  echo "ERROR: directory not found: ${PWD}/secrets/service-accounts"
  exit 1
fi

display_name="${2:-$name}"
project=${3:-${GCLOUD_PROJECT_ID:-planet-4-151612}}

service_account=$name@$project.iam.gserviceaccount.com

set -x

gcloud config set project $project

gcloud iam service-accounts create $name --display-name "$display_name"

gcloud iam service-accounts list

gcloud projects add-iam-policy-binding $project \
  --member="serviceAccount:$service_account" \
  --role roles/storage.admin

gcloud projects add-iam-policy-binding $project \
  --member="serviceAccount:$service_account" \
  --role roles/cloudsql.client

gcloud iam service-accounts describe $service_account --format=json

gcloud iam service-accounts keys list --iam-account=$service_account --format=json

bin/create_service_account_key.sh $name $project
