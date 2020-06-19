#!/usr/bin/env bash
set -eu

should_push=${1:-false}
update_dev=${2:-true}
update_prod=${3:-false}

# Following sites have only a develop environment.
readarray -t all_dev_sites < ./dev_sites.txt

# Following sites have develop, release and production environment.
readarray -t test_prod_sites < ./test_prod_sites.txt
readarray -t actual_prod_sites < ./prod_sites.txt

all_prod_sites=("${test_prod_sites[@]}" "${actual_prod_sites[@]}")

config_header=./templates/nro/.circleci/config-header.yml.tmpl

function update_site() {
  local repo="planet4-$1"
  local is_prod=${2:-false}
  local tmp_config_file="./tmpConfig-$1"
  local generator_hash
  generator_hash="$(git rev-parse HEAD)"
  local generator_link="https://github.com/greenpeace/planet4-nro-generator/blob/${generator_hash}/templates/nro/.circleci/config.yml.tmpl"

  git clone git@github.com:greenpeace/"${repo}".git --single-branch --branch develop --quiet

  if [ ! -f "${repo}"/.circleci/artifacts.yml ]
  then
      echo "${repo} - DOES NOT have an artifacts file. Cannot generate new configuration"
  else
      # Actually dockerize is not a good tool for this script as it grabs everything from the current shell's
      # environment, which it does because it's intended to be used in a docker image entrypoint. It would be safer if
      # we used a template tool that doesn't do that.
      IS_CONFIG_UPDATE=true \
      MAKE_RELEASE=$is_prod \
      MAKE_MASTER=$is_prod \
      dockerize \
      -template "./templates/nro/.circleci/config.yml.tmpl:${tmp_config_file}" \
      -template ${config_header}:"${repo}/config_header.yml"

      cat "${repo}/config_header.yml" "${repo}/.circleci/artifacts.yml" "${tmp_config_file}" > "${repo}/.circleci/config.yml"

      if git -C "${repo}" diff --quiet
      then
          echo "${repo} - No changes needed"
      else
          # If specified push the updated config to the repos.
          if [ "$should_push" = true ]
          then
            git -C "${repo}" commit -m "New CircleCI config" -m "Ref: ${generator_link}" .circleci/config.yml
            git -C "${repo}" push

            echo "${repo} - Generated and pushed new configuration"
          fi
      fi
      rm "$tmp_config_file"
  fi

  # Only remove repo when
  if [ "$should_push" = true ]
  then
    echo "${repo} - Removing git repo."
    rm -rf "${repo}"
  else
    echo "${repo} - Dry run, preserving git repo."
  fi

}

echo "First checking all artifacts.yml files."
if ! ./bin/check_artifacts_matches_config.sh
then
  echo 'Some repositories have changes to config.yml that are not in artifacts.yml, aborting as otherwise these changes would be overwritten.'
  exit 1;
fi

if [ ! "$update_dev" = true ]
then
  echo 'Skipping dev sites.'
else
  for SITE in "${all_dev_sites[@]}"
  do
    update_site "${SITE}" false
  done
fi

if [ ! "$update_prod" = true ]
then
  echo 'Skipping prod sites.'
else
  for SITE in "${all_prod_sites[@]}"
  do
    update_site "${SITE}" true
  done
fi
