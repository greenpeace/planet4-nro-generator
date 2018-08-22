#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]
then
  echo "Usage:"
  echo
  echo " $(basename $0) <service-account-full-name>"
  echo
  exit 1
fi

name=$1
project=${2:-${GCLOUD_PROJECT_ID}}

gcloud config set project $project

gcloud iam service-accounts delete $name@$project.iam.gserviceaccount.com

gcloud iam service-accounts list
