#!/usr/bin/env bash
set -eu

echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo
echo "WARNING: YOU ARE ABOUT TO DELETE A GITHUB REPOSITORY"
echo
echo "https://github.com/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}"
echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo

[[ $FORCE_DELETE = "true" ]] || {
  read -n 1 -rp "Are you sure? [y/N] " yn
  case "$yn" in
      [Yy]* ) : ;;
      * ) exit;;
  esac
}
echo
echo "Deleting github.com/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME} ..."
echo

if curl -i -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -X DELETE https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${GITHUB_REPOSITORY_NAME}
then
  echo "Repository deleted"
else
  echo "ERROR: Failed to delete github repository. Continuing..."
fi
