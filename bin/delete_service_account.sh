#!/usr/bin/env bash
set -eu

name="$1"

gcloud iam service-accounts delete "$1"

gcloud iam service-accounts list
