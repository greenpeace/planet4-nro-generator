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
  git clone -b develop "git@github.com:${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"

  YEAR=$(date +%Y)
  export YEAR

  dockerize \
    -template "templates/LICENSE.tmpl:${GITHUB_REPOSITORY_NAME}/LICENSE"

  pushd "${GITHUB_REPOSITORY_NAME}"  > /dev/null

  git add .

  git commit -m ":robot: Add license"

  git push --set-upstream origin develop

  git remote show origin

  echo
  echo "Develop deployment triggered: https://circleci.com/gh/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}"
  echo
fi

if [[ "${MAKE_RELEASE,,}" != "true" ]]
then
  popd  > /dev/null
  exit 0
fi

git checkout -b release/v0.0.1

git push --set-upstream origin release/v0.0.1

git remote show origin

popd > /dev/null

echo
echo "Release deployment triggered: https://circleci.com/gh/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}/tree/release%2Fv0.0.1"
echo
