#!/usr/bin/env bash
set -eu



echo "User:    ${CIRCLE_PROJECT_USERNAME}"
echo "Project: ${GITHUB_REPOSITORY_NAME}"

curl -u "${CIRCLE_TOKEN}:" -X POST \
  "https://circleci.com/api/v1.1/project/${VCS_TYPE:-github}/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}/follow"
