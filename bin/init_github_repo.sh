#!/usr/bin/env bash
set -eu

# ============================================================================

git config --global user.email "${GITHUB_USER_EMAIL}"
git config --global user.name "${GITHUB_USER_NAME}"
git config push.default simple

git config --global -l

eval "$(ssh-agent)"
ssh-add "${HOME}/.ssh/id_rsa"

# ============================================================================

HTTP_STATUS=
HTTP_RESPONSE=
HTTP_BODY=

function curl_string() {
  str=("$@")
  echo "curl" "${str[@]}"
  HTTP_RESPONSE="$(curl -s --write-out "HTTPSTATUS:%{http_code}" "${str[@]}")"
  HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  # Pure bash search replace is much slower here than sed
  # shellcheck disable=SC2001
  HTTP_BODY=$(sed -e 's/HTTPSTATUS\:.*//g' <<< "$HTTP_RESPONSE")

  [[ $HTTP_STATUS -eq 201 ]] && return
  [[ $HTTP_STATUS -eq 204 ]] && return

  if [[ 300 -le $HTTP_STATUS && $HTTP_STATUS -lt 400 ]]
  then
    >&2 echo "WARNING: HTTP_STATUS $HTTP_STATUS"
    return
  fi

  if [[ 300 -le $HTTP_STATUS ]]
  then
    >&2 echo "ERROR: HTTP_STATUS $HTTP_STATUS"
  fi

  >&2 jq -r <<< "$HTTP_BODY"

}

function get_response_var() {
  jq -M -r "$1" <<< "$HTTP_BODY"
}

# ============================================================================
#
# Create new github repository
#
# shellcheck disable=SC2016
endpoint="https://api.github.com/orgs/${CIRCLE_PROJECT_USERNAME}/repos"
# shellcheck disable=SC2016
json=$(jq -n --arg name "${GITHUB_REPOSITORY_NAME}" '{ name: $name }')

echo
echo "Generating github repository: github.com/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}"
echo
curl_string -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X POST -d "$json" "$endpoint"

# Extract URL to clone later
clone_url=$(get_response_var .ssh_url)

if [[ -z "$clone_url" ]] || [[ $clone_url = "null" ]]
then
  >&2 echo "WARNING: .ssh_url is '$clone_url', attempting to continue..."
  curl_string "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}"
  clone_url=$(get_response_var .ssh_url)
fi

# ============================================================================
#
# Add collaborator bot
#
endpoint="https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}/collaborators/${GITHUB_MACHINE_USER}"
# shellcheck disable=SC2016
json=$(jq -n --arg permissions "admin" '{ permissions: $permissions }')

echo
echo "---------"
echo
echo "Add github machine user as 'admin' collaborator: ${GITHUB_MACHINE_USER}"
echo
curl_string -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X PUT -d "$json" "$endpoint"


# ============================================================================
#
# Add collaborator team "Planet 4 Developers" (We know the ID is: 2496903)
#
endpoint="https://api.github.com/teams/2496903/repos/greenpeace/${GITHUB_REPOSITORY_NAME}"
json='{"permission":"push"}'

echo
echo "---------"
echo
echo "Adding the team 'Planet 4 Developers' as 'write' collaborator"
echo
curl_string -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X PUT -d "$json" "$endpoint"


# ============================================================================
#
# Add collaboror Konstantinos
#
endpoint="https://api.github.com/repos/greenpeace/${GITHUB_REPOSITORY_NAME}/collaborators/koyan"
json='{"permission":"admin"}'

echo
echo "---------"
echo
echo "Adding Konstantinos as owner of the new repo"
echo
curl_string -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X PUT -d "$json" "$endpoint"

# ============================================================================
#
# Add collaboror Ray
#
endpoint="https://api.github.com/repos/greenpeace/${GITHUB_REPOSITORY_NAME}/collaborators/27Bslash6"
json='{"permission":"admin"}'

echo
echo "---------"
echo
echo "Adding Ray as owner of the new repo"
echo
curl_string -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X PUT -d "$json" "$endpoint"



# ============================================================================
#
# Clone new repository and prepare initial content
#
echo
echo "---------"
echo
echo "Cloning repository: $clone_url"

git clone "$clone_url" src

pushd src

git checkout -b develop || git checkout develop
echo
echo "---------"
echo
echo "Syncing template/nro/ into src/"
rsync -a ../templates/nro/ .
echo
echo "---------"
echo
echo "Creating files from template ..."

# Clean empty hostpath value
[[ $APP_HOSTPATH == '""' ]] && APP_HOSTPATH=

dockerize \
  -template .circleci/config.yml.tmpl:.circleci/config.yml \
-template composer-local.json.tmpl:composer-local.json

yamllint -c /app/.yamllint .circleci/config.yml

echo
echo "---------"
echo
echo "Cleaning .tmpl files ..."
find . -type f -name '*.tmpl' -delete

echo
echo "---------"
echo
echo "Staging files ..."
git add .

echo "---------"
echo
echo "Commit ..."
if ! git commit -m ":robot: init"
then
  echo "Nothing to do..."
  exit 0
fi

# ============================================================================
#
# Push new content
#
echo
echo "---------"
echo
echo "Pushing to $clone_url ..."
git push --set-upstream origin develop

git checkout -b master

git merge develop --commit

git push --set-upstream origin master

popd
