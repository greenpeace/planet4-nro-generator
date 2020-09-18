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
  local repo_dir="tmp/update/$repo"
  local is_prod=${2:-false}
  local tmp_config_file="./tmpConfig-$1"
  local generator_hash
  generator_hash="$(git rev-parse HEAD)"
  local generator_link="https://github.com/greenpeace/planet4-nro-generator/blob/${generator_hash}/templates/nro/.circleci/config.yml.tmpl"

  rm -rf "$repo_dir"

  git clone --branch develop --quiet git@github.com:greenpeace/"${repo}".git "$repo_dir"

  if [ ! -f "${repo_dir}"/.circleci/artifacts.yml ]
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
      -template ${config_header}:"${repo_dir}/config_header.yml"

      cat "${repo_dir}/config_header.yml" "${repo_dir}/.circleci/artifacts.yml" "${tmp_config_file}" > "${repo_dir}/.circleci/config.yml"

      if git -C "${repo_dir}" diff --quiet
      then
          echo "${repo} - No changes needed"
      else
          # If specified push the updated config to the repos.
          if [ "$should_push" = true ]
          then
            git -C "${repo_dir}" commit -m "New CircleCI config" -m "Ref: ${generator_link}" .circleci/config.yml
            git -C "${repo_dir}" push

            echo "${repo} - Generated and pushed new configuration"
          fi
      fi
      rm "$tmp_config_file"
  fi

  # Only remove repo when
  if [ "$should_push" = true ]
  then
    echo "${repo} - Removing git repo."
    rm -rf "${repo_dir}"
  else
    echo "${repo} - Dry run, preserving git repo at ${repo_dir}."
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
