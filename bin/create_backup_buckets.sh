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
  gcloud storage ls --project "${GOOGLE_PROJECT_ID}" "gs://${IMAGE_BACKUP_BUCKET_NAME}" >/dev/null && return

  # Make image backup bucket if it doesn't exist

  echo " * gcs: Initialising WP Stateless bucket"
  echo
  echo " * gcs: Project: ${GOOGLE_PROJECT_ID}"
  echo " * gcs: Labels:"
  echo " * gcs:  - NRO:  ${APP_HOSTPATH}"
  echo " * gcs: Bucket:  gs://${IMAGE_BACKUP_BUCKET_NAME}"
  echo " * gcs: Region:  ${STATELESS_BUCKET_LOCATION}"
  echo " * Purpose: Backup of bucket:  gs://${BUCKET}"


  gcloud storage buckets create --project "${GOOGLE_PROJECT_ID}" -l "${STATELESS_BUCKET_LOCATION}" "gs://${IMAGE_BACKUP_BUCKET_NAME}"
  gcloud storage buckets add-iam-policy-binding "gs://${IMAGE_BACKUP_BUCKET_NAME}" --member=serviceAccount:"$(jq -r '.client_email' "secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json")" --role=roles/storage.objectAdmin
  # Apply labels to image backups bucket
  gcloud storage buckets update "gs://${IMAGE_BACKUP_BUCKET_NAME}" \
    --update-labels=app=planet4,environment=production,component=images_backup,nro="${APP_HOSTPATH}"
}


create_db_backup_bucket() {

  DB_BACKUP_BUCKET_NAME=${BUCKET}_db_backup
  gcloud storage ls --project "${GOOGLE_PROJECT_ID}" "gs://${DB_BACKUP_BUCKET_NAME}" >/dev/null && return

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


  gcloud storage buckets create --project "${GOOGLE_PROJECT_ID}" -l "${STATELESS_BUCKET_LOCATION}" "gs://${DB_BACKUP_BUCKET_NAME}"
  gcloud storage buckets add-iam-policy-binding "gs://${DB_BACKUP_BUCKET_NAME}" --member=serviceAccount:"$(jq -r '.client_email' "secrets/service-accounts/${SERVICE_ACCOUNT_NAME}.json")" --role=roles/storage.objectAdmin
  # Apply labels to image backups bucket
  gcloud storage buckets update "gs://${DB_BACKUP_BUCKET_NAME}" \
    --update-labels=app=planet4,environment=production,component=images_backup,nro="${APP_HOSTPATH}"

  # Allow versioning of database files (use storage versioning to keep multiple copies of the SQL!)
  gcloud storage buckets update "gs://${DB_BACKUP_BUCKET_NAME}" --versioning
  gcloud storage buckets update "gs://${DB_BACKUP_BUCKET_NAME}" --lifecycle-file=/app/lifecycle-db.json
}

# Set the normal images bucket to have versioning so that deleted images get retained
gcloud storage buckets update "gs://${_BUCKET}" --versioning

# Retrying here because gcloud storage is flaky, connection resets often
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