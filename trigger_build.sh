#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

curl -u ${CIRCLE_TOKEN}: -X POST https://circleci.com/api/v1.1/project/${VCS_TYPE:-github}/${CIRCLE_PROJECT_USERNAME:-greenpeace}/${CIRCLE_PROJECT_REPONAME}/tree/develop
