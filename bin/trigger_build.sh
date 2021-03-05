#!/usr/bin/env bash
set -eu

eval "$(ssh-agent)"
ssh-add "${HOME}/.ssh/id_rsa"

git config --global user.email "${GITHUB_USER_EMAIL}"
git config --global user.name "${GITHUB_USER_NAME}"
git config push.default simple

if [[ -z "${SSH_AGENT_PID:-}" ]]
then
  eval "$(ssh-agent)"
  ssh-add "${HOME}/.ssh/id_rsa"
fi

if [[ "${MAKE_DEVELOP,,}" = "true" ]]
then
  git clone -b main "git@github.com:${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"

  YEAR=$(date +%Y)
  export YEAR

  dockerize \
    -template "templates/LICENSE.tmpl:${GITHUB_REPOSITORY_NAME}/LICENSE"

  pushd "${GITHUB_REPOSITORY_NAME}"  > /dev/null

  git add .

  git commit -m ":robot: Add license"

  git push --set-upstream origin main

  git remote show origin

  echo
  echo "Develop deployment triggered: https://circleci.com/gh/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}"
  echo
fi

popd > /dev/null
