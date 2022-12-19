#!/usr/bin/env bash
set -eu

echo
echo "========================================================================="
echo
echo "Uninstall helm deployments for ${SERVICE_ACCOUNT_NAME}"
echo

gcloud auth revoke "$SERVICE_ACCOUNT_NAME@${GCP_DEVELOPMENT_PROJECT}.iam.gserviceaccount.com" || true

user=$(gcloud auth list --format=json | jq -r '.[] | select(.account|test("^.+?@greenpeace.org")) | .account')
gcloud config set account "$user"

# auth to dev cluster using account passed through to build container
gcloud container clusters get-credentials p4-development --project planet-4-151612
echo
echo "Uninstall helm release for planet4-${SERVICE_ACCOUNT_NAME}"
echo
helm uninstall -n develop planet4-"${SERVICE_ACCOUNT_NAME}" || true

# auth to prod cluster using account passed through to build container
gcloud container clusters get-credentials planet4-production --zone us-central1-a --project planet4-production
# remove staging
echo
echo "Uninstall helm release for planet4-${SERVICE_ACCOUNT_NAME}-release"
echo
helm uninstall -n "${SERVICE_ACCOUNT_NAME}" planet4-"${SERVICE_ACCOUNT_NAME}"-release || true
# remove production
echo
echo "Uninstall helm release for planet4-${SERVICE_ACCOUNT_NAME}-master"
echo
helm uninstall -n "${SERVICE_ACCOUNT_NAME}" planet4-"${SERVICE_ACCOUNT_NAME}"-master || true
# reauth to dev for safety
gcloud container clusters get-credentials p4-development --project planet-4-151612
