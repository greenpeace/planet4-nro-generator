#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

git config --global user.email "${GITHUB_USER_EMAIL}"
git config --global user.name "${GITHUB_USER_NAME}"
git config push.default simple

eval "$(ssh-agent)"
ssh-add ${HOME}/.ssh/id_rsa

[[ -z "${APP_HOSTPATH:-}" ]] && >&2 echo -e "Error: APP_HOSTPATH is not set.\nUsage: APP_HOSTPATH=international make" && exit 1

# shellcheck disable=2016
json=$(jq -n --arg name "${CIRCLE_PROJECT_REPONAME}" '{ name: $name }')

echo ""
echo "Generating github repository: github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
echo ""
echo "$json"
echo ""
response="$(curl -s -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X POST -d "$json" "https://api.github.com/orgs/${CIRCLE_PROJECT_USERNAME}/repos")"

clone_url=$(jq -M -n -r "$response | .ssh_url")

if [[ $clone_url = "null" ]] && >&2 jq -C -n "$response | ."
then
  >&2 echo "Error creating repository"
  [[ ${CONTINUE_ON_FAIL} = "false" ]] && exit 1 || exit 0
fi

git config --global -l
echo ""
echo "---------"
echo ""
echo "Cloning repository: $clone_url"

git clone "$clone_url" src

pushd src

git checkout -b develop
echo ""
echo "---------"
echo ""
echo "Syncing template/nro/ into src/"
rsync -a ../templates/nro/ .
echo ""
echo "---------"
echo ""
echo "Creating files from template ..."

dockerize \
  -template .circleci/config.yml.tmpl:.circleci/config.yml \
  -template composer-local.json.tmpl:composer-local.json

echo ""
echo "---------"
echo ""
echo "Cleaning .tmpl files ..."
find . -type f -name '*.tmpl' -delete

echo ""
echo "---------"
echo ""
echo "Staging files ..."
git add .

echo ""
echo "---------"
echo ""
echo "Commit ..."
git commit -m ":robot: init"

echo ""
echo "---------"
echo ""
echo "Pushing to $clone_url ..."
git push --set-upstream origin develop

git checkout -b master

git merge develop --commit

git push --set-upstream origin master

popd
