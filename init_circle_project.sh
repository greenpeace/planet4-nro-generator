#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

echo "User:    ${CIRCLE_PROJECT_USERNAME:-greenpeace}"
echo "Project: ${CIRCLE_PROJECT_REPONAME}"

curl -u ${CIRCLE_TOKEN}: -X POST \
  https://circleci.com/api/v1.1/project/${VCS_TYPE:-github}/${CIRCLE_PROJECT_USERNAME:-greenpeace}/${CIRCLE_PROJECT_REPONAME}/follow
