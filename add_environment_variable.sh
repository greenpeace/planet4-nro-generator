#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

key=${1}
value=${2}

echo "User:    ${CIRCLE_PROJECT_USERNAME:-greenpeace}"
echo "Project: ${CIRCLE_PROJECT_REPONAME}"
echo "Key:     ${key}"

json=$(jq -n --arg key "$key" --arg value "$value" '{ name: $key, value: $value }')

curl -u ${CIRCLE_TOKEN}: -X POST --header "Content-Type: application/json" -d "$json" \
  https://circleci.com/api/v1.1/project/${VCS_TYPE:-github}/${CIRCLE_PROJECT_USERNAME:-greenpeace}/${CIRCLE_PROJECT_REPONAME}/envvar

echo ""
