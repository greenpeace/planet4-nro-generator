#!/usr/bin/env bash
set -eu

function file_contained_in_other_file() {
  local needle=$1
  local haystack=$2

  if grep --quiet "$(tr '\n' ' ' < "$needle")" <<< "$(tr '\n' ' ' < "$haystack")"
  then
    true
  else
    false
  fi
}

readarray -t dev_sites < dev_sites.txt
readarray -t test_prod_sites < test_prod_sites.txt
readarray -t prod_sites < prod_sites.txt

sites=("${dev_sites[@]}" "${test_prod_sites[@]}" "${prod_sites[@]}")

all_valid=true
tmp_dir=tmp/detect
mkdir -p $tmp_dir

for site in "${sites[@]}"
do
  repo="planet4-${site}"
  rm -rf "${tmp_dir:?}/${repo}"
  git -C ${tmp_dir} clone https://github.com/greenpeace/"${repo}" --quiet --single-branch --branch main

  if ! file_contained_in_other_file "$tmp_dir/$repo/.circleci/artifacts.yml" "$tmp_dir/$repo/.circleci/config.yml"
  then
    echo "${repo} ❌ artifacts.yml file is out of sync. Please check and resolves differences."
    all_valid=false
  else
    echo "${repo} ✅"
  fi
done

if [ "${all_valid}" = true ]
then
  echo "All files in sync."
  exit 0;
else
  echo "Detected out of sync files."
  exit 1;
fi

