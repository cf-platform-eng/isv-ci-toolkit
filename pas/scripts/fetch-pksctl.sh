#!/usr/bin/env bash

if [[ -z "${CFENG_REPO_KEY}" ]] ; then
    >&2 echo "CFENG_REPO_KEY must be defined"
    exit 1
fi

REPO="pivotal/pe-pixie"
VERSION=$1                       
GITHUB="https://api.github.com"

function gh_curl() {
  curl -H "Authorization: token $CFENG_REPO_KEY" \
       -H "Accept: application/vnd.github.v3.raw" \
       "$@"
}

asset_id=$(gh_curl -s "$GITHUB/repos/$REPO/releases/tags/$VERSION" | jq '.assets[] | select(.name | endswith("linux")) | .id')

if [ "$asset_id" = "null" ]; then
  >&2 echo "ERROR: pksctl version not found $VERSION"
  exit 1
fi;

wget -q --auth-no-challenge --header='Accept:application/octet-stream' \
  "https://$CFENG_REPO_KEY:@api.github.com/repos/$REPO/releases/assets/$asset_id" \
  -O "$2"
