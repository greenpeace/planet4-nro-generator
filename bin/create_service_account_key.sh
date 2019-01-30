#!/usr/bin/env bash
set -eu

[[ -z "${1:-}" ]] && echo "Usage: $(basename "$0") <service-account-name> [<project>]" && exit 1

if [[ ! -d "secrets/service-accounts" ]]
then
  echo "ERROR: directory not found: ${PWD}/secrets/service-accounts"
  exit 1
fi

name=$1
project=${2:-${GCLOUD_PROJECT_ID:-planet-4-151612}}
service_account="$name@$project.iam.gserviceaccount.com"

set -x

gcloud config set project "$project"

gcloud iam service-accounts keys list --iam-account="$service_account" --format=json

gcloud iam service-accounts keys create "secrets/service-accounts/$name.json" --iam-account="$service_account"
