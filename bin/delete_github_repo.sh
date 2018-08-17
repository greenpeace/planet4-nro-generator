#!/usr/bin/env bash
set -eu

[[ -f secrets/env ]] && source secrets/env



echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo
echo "WARNING: YOU ARE ABOUT TO DELETE A GITHUB REPOSITORY"
echo
echo "https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo

read -p "Are you sure? [y/N] " yn
case $yn in
    [Yy]* ) : ;;
    * ) exit;;
esac

echo
echo "Deleting github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} ..."
echo

curl -i -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X DELETE https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}
