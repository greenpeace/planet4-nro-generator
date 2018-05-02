#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env

echo ""
echo "YOU ARE ABOUT TO DELETE https://github.com/${CIRCLE_PROJECT_USERNAME:-greenpeace}/${CIRCLE_PROJECT_REPONAME}"
echo ""

read -p "Are you sure? [y/N] " yn
case $yn in
    [Yy]* ) : ;;
    * ) exit;;
esac

echo ""
echo "Deleting github.com/${CIRCLE_PROJECT_USERNAME:-greenpeace}/${CIRCLE_PROJECT_REPONAME} ..."
echo ""

curl -i -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X DELETE https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME:-greenpeace}/${CIRCLE_PROJECT_REPONAME}
