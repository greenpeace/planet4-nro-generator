#!/usr/bin/env bash
set -eu

gsutil ls -p "${PROJECT}" "gs://${BUCKET}" || gsutil mb -p "${PROJECT}" "gs://${BUCKET}"

gsutil iam ch allUsers:objectViewer "gs://${BUCKET}"

gsutil iam ch "serviceAccount:$(jq -r '.client_email' secrets/stateless-service-account.json):admin" "gs://${BUCKET}"

gsutil -m rsync -r -d "gs://${SOURCE_CONTENT_BUCKET}/uploads/" "gs://${BUCKET}"
