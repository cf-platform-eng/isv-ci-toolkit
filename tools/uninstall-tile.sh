#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: uninstall-tile.sh <tile>"
}

uninstall_tile() {
    TILE=$1

    PRODUCT_NAME=$(tileinspect metadata -t "${TILE}" | yq -r .name)
    PRODUCT_VERSION=$(tileinspect metadata -t "${TILE}" | yq -r .product_version)

    if ! om unstage-product -p "${PRODUCT_NAME}" ; then 
        echo "Failed to unstage product ${PRODUCT_NAME}" >&2
        return 1
    fi

    if ! om apply-changes ; then
        echo "Failed to apply changes" >&2
        return 1
    fi

    if ! om delete-product -p "${PRODUCT_NAME}" -v "${PRODUCT_VERSION}" ; then
        echo "Failed to delete version ${PRODUCT_VERSION} of ${PRODUCT_NAME}"
        return 1
    fi
}

if [ "$#" -lt 1 ]; then    
    usage
    exit 1
fi

uninstall_tile "$1"
