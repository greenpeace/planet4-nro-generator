#!/usr/bin/env bash
set -eu

# Authenticate with wp-stateless account to ensure we can pull from SQL bucket
gcloud auth activate-service-account --key-file secrets/service-account/${NRO}.json

##############################################################################

ENVIRONMENT="development" \
BUCKET=${CONTAINER_PREFIX}-stateless-develop \
PROJECT=${GCP_DEVELOPMENT_PROJECT} \
create_stateless_bucket.sh

##############################################################################

if [[ ${MAKE_RELEASE,,} = "true" ]]
then
  ENVIRONMENT="staging" \
  BUCKET=${CONTAINER_PREFIX}-stateless-release \
  PROJECT=${GCP_PRODUCTION_PROJECT} \
  create_stateless_bucket.sh
fi

##############################################################################

if [[ ${MAKE_MASTER,,} = "true" ]]
then
  ENVIRONMENT="production" \
  BUCKET=${CONTAINER_PREFIX}-stateless \
  PROJECT=${GCP_PRODUCTION_PROJECT} \
  create_stateless_bucket.sh
fi
