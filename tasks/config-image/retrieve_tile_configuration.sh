#!/bin/bash

JSON_FILE=$1
PCF_VERSION=$2
TILE_VERSION=$3

set -x
count=0
index=0

[[ $PCF_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
PCF_VERSION_MATCH="${BASH_REMATCH[0]}"

[[ $TILE_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
TILE_VERSION_MATCH="${BASH_REMATCH[0]}"

while read i; do
  semver $PCF_VERSION_MATCH -r "$i" &>/dev/null
  if [[ "0" = "$?" ]]; then
    j=$(jq -cr ".[$index] | .version_ranges.tile_version" "$JSON_FILE")
    semver $TILE_VERSION_MATCH -r "$j" &>/dev/null
    if [[ "0" = "$?" ]]; then
      count=$((count+1))
      if [[ $count -gt 1 ]]; then
        echo "Found multiple configurations matching the version combination."
        exit 1
      else
        config=$(jq -r ".[$index] | .config" "$JSON_FILE")
      fi
    fi
  fi
  index=$((index+1))
done < <(jq -cr '.[] | .version_ranges.pcf_version' "$JSON_FILE")

if [[ -z ${config} ]]; then
  echo "Could not find configuration matching the version combination."
  exit 1
else
  echo $config
fi
