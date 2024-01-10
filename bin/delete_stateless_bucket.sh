#!/usr/bin/env bash
set -eu

echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo
echo "WARNING: YOU ARE ABOUT TO DELETE ALL WP-STATELESS CONTENT"
echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo

echo "Bucket:    ${BUCKET}"
echo
echo "This can not be undone!"
echo
[[ $FORCE_DELETE = "true" ]] || {
  read -n 1 -rp "Are you sure? [y/N] " yn
  case "$yn" in
      [Yy]* ) : ;;
      * ) exit;;
  esac
}

gcloud storage ls "gs://${BUCKET}" || exit 0

gcloud storage rm -r "gs://${BUCKET}"
