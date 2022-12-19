#!/usr/bin/env bash
set -euo pipefail

if [ -z ${APP_ENVIRONMENT+x} ]; then
  APP_ENVIRONMENT="production"
fi

[[ ${APP_ENVIRONMENT} =~ production ]] || {
  echo "Non-prod environment: skipping database backup"
  exit 0
}

create_image_backup_bucket() {

  IMAGE_BACKUP_BUCKET_NAME=${BUCKET}_images_backup
  gsutil ls -p "${GOOGLE_PROJECT_ID}" "gs://${IMAGE_BACKUP_BUCKET_NAME}" >/dev/null && return

  # Make image backup bucket if it doesn't exist

  echo " * gcs: Initialising WP Stateless bucket"
  echo
  echo " * gcs: Project: ${GOOGLE_PROJECT_ID}"
  echo " * gcs: Labels:"
  echo " * gcs:  - NRO:  ${APP_HOSTPATH}"
  echo " * gcs: Bucket:  gs://${IMAGE_BACKUP_BUCKET_NAME}"
  echo " * gcs: Region:  ${STATELESS_BUCKET_LOCATION}"
  echo " * Purpose: Backup of bucket:  gs://${BUCKET}"


  gsutil mb -l "${STATELESS_BUCKET_LOCATION}" -p "${GOOGLE_PROJECT_ID}" "gs://${IMAGE_BACKUP_BUCKET_NAME}"
  gsutil -m iam -R ch "serviceAccount:$(jq -r '.client_email' "secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json"):objectAdmin" "gs://${IMAGE_BACKUP_BUCKET_NAME}"
  # Apply labels to image backups bucket
  gsutil label ch \
    -l "app:planet4" \
    -l "environment:production" \
    -l "component:images_backup" \
    -l "nro:${APP_HOSTPATH}" \
    "gs://${IMAGE_BACKUP_BUCKET_NAME}"

}


create_db_backup_bucket() {

  DB_BACKUP_BUCKET_NAME=${BUCKET}_db_backup
  gsutil ls -p "${GOOGLE_PROJECT_ID}" "gs://${DB_BACKUP_BUCKET_NAME}" >/dev/null && return

  # Make image backup bucket if it doesn't exist
  if [ -z ${APP_ENVIRONMENT+x} ]; then
    APP_ENVIRONMENT="production"
  fi

  echo " * gcs: Initialising WP Stateless bucket"
  echo
  echo " * gcs: Project: ${GOOGLE_PROJECT_ID}"
  echo " * gcs: Labels:"
  echo " * gcs:  - NRO:  ${APP_HOSTPATH}"
  echo " * gcs: Bucket:  gs://${DB_BACKUP_BUCKET_NAME}"
  echo " * gcs: Region:  ${STATELESS_BUCKET_LOCATION}"
  echo " * Purpose: Backup of bucket:  gs://${BUCKET}"


  gsutil mb -l "${STATELESS_BUCKET_LOCATION}" -p "${GOOGLE_PROJECT_ID}" "gs://${DB_BACKUP_BUCKET_NAME}"
  gsutil -m iam -R ch "serviceAccount:$(jq -r '.client_email' "secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json"):objectAdmin" "gs://${DB_BACKUP_BUCKET_NAME}"

  # Apply labels to image backups bucket
  gsutil label ch \
    -l "app:planet4" \
    -l "environment:production" \
    -l "component:db_backup" \
    -l "nro:${APP_HOSTPATH}" \
    "gs://${DB_BACKUP_BUCKET_NAME}"

  # Allow versioning of database files (use storage versioning to keep multiple copies of the SQL!)
  gsutil versioning set on "gs://${DB_BACKUP_BUCKET_NAME}"
  gsutil lifecycle set /app/lifecycle-db.json "gs://${DB_BACKUP_BUCKET_NAME}"
}

# Set the normal images bucket to have versioning so that deleted images get retained
gsutil versioning set on "gs://${BUCKET}"

# Retrying here because gsutil is flaky, connection resets often
echo "Create GCS buckets to store backup data ..."
okay=0
i=0
retry=3

while [[ $okay -ne 1 ]]
do
  create_image_backup_bucket
  create_db_backup_bucket

  [[ $okay -eq 1 ]] && exit

  i=$(( i + 1 ))
  [[ $i -gt $retry ]] && break
  echo "Retry: $i/$retry"
done