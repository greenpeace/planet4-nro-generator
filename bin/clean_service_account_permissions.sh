#!/usr/bin/env bash
set -eu# post bucket creation

echo
echo "========================================================================="
echo
echo "Removing storage.admin permission for ${SERVICE_ACCOUNT_NAME}"
echo

gcloud auth revoke "$SERVICE_ACCOUNT_NAME@${GCP_DEVELOPMENT_PROJECT}.iam.gserviceaccount.com"

service_account=$SERVICE_ACCOUNT_NAME@${GCP_DEVELOPMENT_PROJECT}.iam.gserviceaccount.com
# this access is removed at the end of the script
gcloud projects remove-iam-policy-binding "${GCP_DEVELOPMENT_PROJECT}" \
  --member="serviceAccount:$service_account" \
--role roles/storage.admin

gcloud projects remove-iam-policy-binding "${GCP_PRODUCTION_PROJECT}" \
  --member="serviceAccount:$service_account" \
--role roles/storage.admin