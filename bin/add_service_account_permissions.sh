#!/usr/bin/env bash
set -eu

echo
echo "========================================================================="
echo
echo "Adding storage.admin permission for ${SERVICE_ACCOUNT_NAME}"
echo

user=$(gcloud auth list --format=json | jq -r '.[] | select(.account|test("^.+?@greenpeace.org")) | .account' | sed -n '1{p;q}')
gcloud config set account "$user"

service_account=$SERVICE_ACCOUNT_NAME@${GCP_DEVELOPMENT_PROJECT}.iam.gserviceaccount.com
# this access is removed at the end of the script
gcloud projects add-iam-policy-binding "${GCP_DEVELOPMENT_PROJECT}" \
  --member="serviceAccount:$service_account" \
  --role roles/storage.admin

gcloud projects add-iam-policy-binding "${GCP_PRODUCTION_PROJECT}" \
  --member="serviceAccount:$service_account" \
  --role roles/storage.admin
