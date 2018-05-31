#!/usr/bin/env bash
set -eu

echo "Initialising WP Stateless bucket"
echo ""
echo "Project: ${PROJECT}"
echo "Labels:"
echo " - nro:         ${APP_HOSTPATH}"
echo " - environment: ${ENVIRONMENT}"
echo "Bucket:  gs://${BUCKET}"
echo "Region:  ${STATELESS_BUCKET_REGION}"
echo ""

gsutil ls -p "${PROJECT}" "gs://${BUCKET}" || gsutil mb -l "${STATELESS_BUCKET_REGION}" -p "${PROJECT}" "gs://${BUCKET}"

gsutil -m iam -R ch allUsers:objectViewer "gs://${BUCKET}"

gsutil -m iam -R ch "serviceAccount:$(jq -r '.client_email' secrets/stateless-service-account.json):admin" "gs://${BUCKET}"

# FIXME define NRO_LABEL variable instead of relying on APP_HOSTPATH
gsutil label ch -l "nro:${APP_HOSTPATH}" "gs://${BUCKET}"
gsutil label ch -l "environment:${ENVIRONMENT}" "gs://${BUCKET}"

gsutil -m rsync -r -d "gs://${SOURCE_CONTENT_BUCKET}/uploads/" "gs://${BUCKET}"
