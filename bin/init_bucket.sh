#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

# Authenticate with wp-stateless account to ensure we can pull from SQL bucket
gcloud auth activate-service-account --key-file secrets/stateless-service-account.json

##############################################################################

BUCKET=${CONTAINER_PREFIX}-stateless-develop \
PROJECT=${GCP_DEVELOPMENT_PROJECT} \
create_stateless_bucket.sh

##############################################################################

if [[ ${MAKE_RELEASE,,} = "true" ]]
then
  BUCKET=${CONTAINER_PREFIX}-stateless-release \
  PROJECT=${GCP_PRODUCTION_PROJECT} \
  create_stateless_bucket.sh
fi

##############################################################################

if [[ ${MAKE_MASTER,,} = "true" ]]
then
  BUCKET=${CONTAINER_PREFIX}-stateless \
  PROJECT=${GCP_PRODUCTION_PROJECT} \
  create_stateless_bucket.sh
fi
