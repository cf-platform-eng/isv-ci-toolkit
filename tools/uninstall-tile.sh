#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: uninstall-tile.sh <tile> [<full deploy>]"
    echo "    tile - path to a .pivotal file"
    echo "    full deploy - if true, deploys all products, otherwise only deploys this tile (default false)"
}

uninstall_tile() {
    TILE=$1
    USE_FULL_DEPLOY=$2

    PRODUCT_NAME=$(tileinspect metadata --tile "${TILE}" --format json | jq -r .name)
    PRODUCT_VERSION=$(tileinspect metadata --tile "${TILE}" --format json | jq -r .product_version)

    if ! om unstage-product --product-name "${PRODUCT_NAME}" ; then 
        echo "Failed to unstage product ${PRODUCT_NAME}" >&2
        return 1
    fi

    SELECTIVE_DEPLOY_ARG=(" " --product-name "${PRODUCT_NAME}")
    if [ "${USE_FULL_DEPLOY}" == "true" ] ; then
      SELECTIVE_DEPLOY_ARG=("")
    fi

    # shellcheck disable=SC2086
    if ! om apply-changes${SELECTIVE_DEPLOY_ARG[*]} ; then
        echo "Failed to apply changes" >&2
        echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
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
