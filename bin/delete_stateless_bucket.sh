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
read -p "Are you sure? [y/N] " yn
case $yn in
    [Yy]* ) : ;;
    * ) exit;;
esac

gsutil ls "gs://${BUCKET}" || exit 0

gsutil -m rm -r "gs://${BUCKET}"
