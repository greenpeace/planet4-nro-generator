#!/usr/bin/env bash
set -eu

[[ -z "${1:-}" ]] && echo "Usage: $(basename $0) <service-account-name>" && exit 1

name=$1
display_name="${2:-$name}"ZA
project=${3:-${GCLOUD_PROJECT_ID:-planet-4-151612}}

service_account=$name@$project.iam.gserviceaccount.com

set -x

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

gcloud iam service-accounts keys create "secrets/service-accounts/$name.json" --iam-account=$service_account
