#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: om-helper.sh stemcell-assignments [--unmet]"
}

stemcell-assignments() {
    STEMCELL_ASSIGNMENTS="$(om curl --silent --path /api/v0/stemcell_assignments)"
    STEMCELLS="$(echo "${STEMCELL_ASSIGNMENTS}" | jq -c '.products | 
    map(select( .required_stemcell_os ) | 
        select( .required_stemcell_version)) | 
    map({
        product: .guid,
        os: .required_stemcell_os,
        version: .required_stemcell_version,
        unmet: (.staged_stemcell_version == null)
    })')"

    if [ "$#" -gt 0 ]; then
        SUBCOMMAND=$1
        case ${SUBCOMMAND} in
            --unmet | -u)
                STEMCELLS=$(echo "${STEMCELLS}" | jq -c '[.[] | select(.unmet == true)]')
                ;;
        esac
    fi

    echo "$STEMCELLS"
}

if [ "$#" -lt 1 ]; then    
    usage
    exit 1
fi

COMMAND=$1

case ${COMMAND} in
    help)
        usage
        ;;
    stemcell-assignments)
        shift
        # shellcheck disable=SC2068
        stemcell-assignments $@
        ;;
    *)
        echo "Unknown command: ${COMMAND}"
        usage
        exit 1
        ;;
esac


