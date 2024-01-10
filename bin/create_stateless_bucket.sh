#!/usr/bin/env bash
set -eu
echo
echo "========================================================================="
echo
echo "Initialising WP Stateless bucket"
echo
echo "Project: ${PROJECT}"
echo "Labels:"
echo " - nro:         ${APP_HOSTPATH}"
echo " - environment: ${ENVIRONMENT}"
echo "Bucket:  gs://${BUCKET}"
echo "Region:  ${STATELESS_BUCKET_LOCATION}"
echo

function init_bucket() {
  set +e

  # Create bucket if it doesn't exist
  gcloud storage ls --project "${PROJECT}" "gs://${BUCKET}" || gcloud storage buckets create --project "${PROJECT}" -l "${STATELESS_BUCKET_LOCATION}" "gs://${BUCKET}"

  # Set public read access
  gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" --member=allUsers --role=roles/storage.objectViewer

  # Set owner
  gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" --member=serviceAccount:"$(jq -r '.client_email' "secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json")" --role=roles/storage.objectAdmin

  # FIXME define NRO_LABEL variable instead of relying on APP_HOSTPATH
  gcloud storage buckets update "gs://${BUCKET}" \
    --update-labels=environment="${ENVIRONMENT}",nro="${APP_HOSTPATH}"

  # Sync the default content to the new bucket
  gcloud storage rsync "gs:/${SOURCE_CONTENT_BUCKET}/uploads/" "gs://${BUCKET}" --recursive --delete-unmatched-destination-objects

  okay=1
  set -e
}

# Solves Google Cloud Shell + gcloud connection errors
okay=0
i=0
retry=3

while [[ $okay -ne 1 ]]
do
  init_bucket

  [[ $okay -eq 1 ]] && exit

  i=$(( i + 1 ))
  [[ $i -gt $retry ]] && break
  echo "Retry: $i/$retry"
done

echo "FAILED initialising bucket gs://${BUCKET}" && exit 1
