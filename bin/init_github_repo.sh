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
  HTTP_BODY=$(sed -e 's/HTTPSTATUS\:.*//g' <<<"$HTTP_RESPONSE")

  [[ $HTTP_STATUS -eq 201 ]] && return
  [[ $HTTP_STATUS -eq 204 ]] && return

  if [[ 300 -le $HTTP_STATUS && $HTTP_STATUS -lt 400 ]]; then
    echo >&2 "WARNING: HTTP_STATUS $HTTP_STATUS"
    return
  fi

  if [[ 300 -le $HTTP_STATUS ]]; then
    echo >&2 "ERROR: HTTP_STATUS $HTTP_STATUS"
  fi

  jq >&2 -r <<<"$HTTP_BODY"

}

function get_response_var() {
  jq -M -r "$1" <<<"$HTTP_BODY"
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

if [[ -z "$clone_url" ]] || [[ $clone_url = "null" ]]; then
  echo >&2 "WARNING: .ssh_url is '$clone_url', attempting to continue..."
  curl_string "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}"
  clone_url=$(get_response_var .ssh_url)
fi

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
# Add collaborator team "Planet4 Admins" (We know the ID is: 3188121)
#
endpoint="https://api.github.com/teams/3188121/repos/greenpeace/${GITHUB_REPOSITORY_NAME}"
json='{"permission":"admin"}'

echo
echo "---------"
echo
echo "Adding the team 'Planet4 Admins' as 'admin' collaborator"
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

git checkout -b main || git checkout main
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

tmp_config=.circleci/config.tmp

dockerize \
  -template .circleci/config.yml.tmpl:${tmp_config} \
  -template .circleci/config-header.yml.tmpl:.circleci/config_header.tmp \
  -template composer-local.json.tmpl:composer-local.json \
  -template README.md.tmpl:README.md

cat ".circleci/config_header.tmp" "${tmp_config}" >".circleci/config.yml"

yamllint -c /app/.yamllint .circleci/config.yml

echo
echo "---------"
echo
echo "Cleaning .tmpl and .tmp files ..."
find . -type f -name '*.tmpl' -delete
find . -type f -name '*.tmp' -delete

echo
echo "---------"
echo
echo "Staging files ..."
git add .

echo "---------"
echo
echo "Commit ..."
if ! git commit -m ":robot: init"; then
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
git push --set-upstream origin main

popd
