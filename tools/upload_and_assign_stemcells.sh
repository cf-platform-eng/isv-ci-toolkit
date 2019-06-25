#!/usr/bin/env bash

# FIXME needs tests, as this is now a dependency

IAAS=$1

if [[ -z $IAAS ]]; then
    echo "no iaas provided"
    exit 1
fi

STEMCELL_ASSIGNMENTS="$(om -k curl -s -p /api/v0/stemcell_assignments)"
STEMCELL_ASSIGNMENTS=$(echo "$STEMCELL_ASSIGNMENTS" | jq '[.products[] | select(.staged_stemcell_version == null) | {product: .identifier, required_stemcell_os: .required_stemcell_os, required_stemcell_version: .required_stemcell_version}]')

PRODUCTS=($(echo "$STEMCELL_ASSIGNMENTS" | jq .[].required_stemcell_os))
STEMCELL_OSES=($(echo "$STEMCELL_ASSIGNMENTS" | jq .[].required_stemcell_os))
STEMCELL_VERSIONS=($(echo "$STEMCELL_ASSIGNMENTS" | jq .[].required_stemcell_version))

if [[ ${#PRODUCTS[@]} -eq 0 ]]; then
  echo "No stemcells need to be uploaded"
  exit 0
fi

mkdir -p stemcells
pushd stemcells
  limit=$(expr ${#PRODUCTS[@]} - 1)
  for i in $(seq 0 $limit)
  do
    marman download-stemcell -o "${STEMCELL_OSES[$i]}" -v "${STEMCELL_VERSIONS[$i]}" -i $IAAS
  done
popd

for stemcell in stemcells/*.tgz
do
  om -k upload-stemcell -s $stemcell
done

