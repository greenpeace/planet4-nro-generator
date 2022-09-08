#!/usr/bin/env bash
set -eu

##############################################################################

BUCKET=${CONTAINER_PREFIX}-stateless-develop \
  PROJECT=${GCP_DEVELOPMENT_PROJECT} \
  delete_stateless_bucket.sh

##############################################################################

if [[ ${MAKE_RELEASE,,} = "true" ]]; then
  BUCKET=${CONTAINER_PREFIX}-stateless-release \
    PROJECT=${GCP_PRODUCTION_PROJECT} \
    delete_stateless_bucket.sh
fi

##############################################################################

if [[ ${MAKE_MASTER,,} = "true" ]]; then
  BUCKET=${CONTAINER_PREFIX}-stateless \
    PROJECT=${GCP_PRODUCTION_PROJECT} \
    delete_stateless_bucket.sh
fi
