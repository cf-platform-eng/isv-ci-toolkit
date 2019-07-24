#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: uninstall-tile.sh <tile> [<selective deploy>]"
    echo "    tile - path to a .pivotal file"
    echo "    selective deploy - if true, only deploy this tile (default false)"
}

uninstall_tile() {
    TILE=$1
    USE_SELECTIVE_DEPLOY=$2

    PRODUCT_NAME=$(tileinspect metadata -t "${TILE}" | yq -r .name)
    PRODUCT_VERSION=$(tileinspect metadata -t "${TILE}" | yq -r .product_version)

    if ! om unstage-product --product-name "${PRODUCT_NAME}" ; then 
        echo "Failed to unstage product ${PRODUCT_NAME}" >&2
        return 1
    fi

    SELECTIVE_DEPLOY_ARG=""
    if [ "${USE_SELECTIVE_DEPLOY}" == "true" ] ; then
        SELECTIVE_DEPLOY_ARG=(--product-name "${PRODUCT_NAME}")
    fi

    if ! om apply-changes ${SELECTIVE_DEPLOY_ARG[*]} ; then
        echo "Failed to apply changes" >&2
        return 1
    fi

    if ! om delete-product --product-name "${PRODUCT_NAME}" --product-version "${PRODUCT_VERSION}" ; then
        echo "Failed to delete version ${PRODUCT_VERSION} of ${PRODUCT_NAME}"
        return 1
    fi
}

if [ "$#" -lt 1 ]; then    
    usage
    exit 1
fi

uninstall_tile "$1" "${2:-false}"
