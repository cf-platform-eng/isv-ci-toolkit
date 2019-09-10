#!/usr/bin/env bash

IAAS=$1
if [[ -z ${IAAS} ]]; then
    echo "no iaas provided"
    exit 1
fi

if ! UNMET_STEMCELLS="$(om-helper.sh stemcell-assignments --unmet)" ; then
  echo "Failed to get the list of unmet stemcells from OpsManager" >&2
  exit 1
fi

COUNT=$(echo "${UNMET_STEMCELLS}" | jq '. | length')
if [[ "${COUNT}" = "0" ]]; then
  echo "No stemcells need to be uploaded"
  exit 0
elif [[ -z "${PIVNET_TOKEN}" ]]; then
  echo "This test requires stemcells to be downloaded from the Pivotal Network, but no PIVNET_TOKEN was given."
  echo "Please, re-run this test with a PIVNET_TOKEN defined."
  exit 1
fi

stemcellList=()
while IFS='' read -r line; do stemcellList+=("$line"); done < <(echo "${UNMET_STEMCELLS}" | jq -c '.[]')

mkdir -p stemcells
cd stemcells || exit
for stemcell in "${stemcellList[@]}"; do
  os=$(echo "${stemcell}" | jq -r .os)
  version=$(echo "${stemcell}" | jq -r .version)
  echo "Downloading stemcell ${os} ${version} for ${IAAS} from pivnet..."
  if ! marman download-stemcell --os "${os}" --version "${version}" --iaas "${IAAS}" ; then
    echo "Failed to download stemcell" >&2
    exit 1
  fi
done
cd ..

for stemcell in stemcells/*.tgz
do
  echo "Uploading ${stemcell} to OpsManager..."
  if ! om upload-stemcell -s "${stemcell}" ; then
    echo "Failed to upload stemcell" >&2
    exit 1
  fi
done
