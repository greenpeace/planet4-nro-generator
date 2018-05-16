#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

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

git clone -b develop "git@github.com:${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git"

YEAR=$(date +%Y)
export YEAR

dockerize \
  -template "templates/LICENSE.tmpl:${CIRCLE_PROJECT_REPONAME}/LICENSE"

pushd "${CIRCLE_PROJECT_REPONAME}"

git add .

git commit -m ":robot: Add license"

git push --set-upstream origin develop

git remote show origin

echo ""
echo "Develop deployment triggered: https://circleci.com/gh/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
echo ""

if [[ "${MAKE_RELEASE,,}" != "true" ]]
then
  popd
  exit 0
fi

git checkout -b release/v0.0.1

git push --set-upstream origin release/v0.0.1

git remote show origin

popd

echo ""
echo "Release deployment triggered: https://circleci.com/gh/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/tree/release%2Fv0.0.1"
echo ""
