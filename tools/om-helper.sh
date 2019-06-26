#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: om-helper.sh stemcell-assignments [--unmet]"
}

stemcell-assignments() {
    STEMCELL_ASSIGNMENTS="$(om curl -s -p /api/v0/stemcell_assignments)"
    STEMCELL_ASSIGNMENTS=$(echo "${STEMCELL_ASSIGNMENTS}" | jq '[.products[] | select(.staged_stemcell_version == null) | {product: .identifier, required_stemcell_os: .required_stemcell_os, required_stemcell_version: .required_stemcell_version}]')

    mapfile -t PRODUCTS < <(echo "${STEMCELL_ASSIGNMENTS}" | jq .[].required_stemcell_os)
    mapfile -t STEMCELL_OSES < <(echo "${STEMCELL_ASSIGNMENTS}" | jq .[].required_stemcell_os)
    mapfile -t STEMCELL_VERSIONS < <(echo "${STEMCELL_ASSIGNMENTS}" | jq .[].required_stemcell_version)

    if [ "$#" -lt 2 ]; then    
    fi
}

if [ "$#" -lt 1 ]; then    
    usage
    exit 1
fi

COMMAND=$1

case ${COMMAND} in
    stemcell-assignments)
        stemcell-assignments
        ;;
    *)
        usage
        ;;
esac


