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
  gsutil ls -p "${PROJECT}" "gs://${BUCKET}" || gsutil mb -l "${STATELESS_BUCKET_LOCATION}" -p "${PROJECT}" "gs://${BUCKET}"

  gsutil -m iam -R ch allUsers:objectViewer "gs://${BUCKET}"

  gsutil -m iam -R ch "serviceAccount:$(jq -r '.client_email' secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json):admin" "gs://${BUCKET}"

  # FIXME define NRO_LABEL variable instead of relying on APP_HOSTPATH
  gsutil label ch -l "nro:${APP_HOSTPATH}" "gs://${BUCKET}"
  gsutil label ch -l "environment:${ENVIRONMENT}" "gs://${BUCKET}"

  gsutil -m rsync -r -d "gs://${SOURCE_CONTENT_BUCKET}/uploads/" "gs://${BUCKET}"

  okay=1
  set -e
}

okay=0
i=0
retry=3

while [[ $okay -ne 1 ]]
do
  init_bucket

  [[ $okay -eq 1 ]] && exit

  i=$(($i+1))
  [[ $i -gt $retry ]] && break
  echo "Retry: $i/$retry"
done

echo "FAILED init_bucketialising bucket gs://${BUCKET}" && exit 1
