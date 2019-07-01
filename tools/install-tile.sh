#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: install-tile.sh <tile> <config.yml>"
}

install_tile() {
    TILE=$1
    TILE_CONFIG=$2

    PRODUCT_NAME=$(tileinspect metadata -t "${TILE}" | yq -r .name)
    PRODUCT_VERSION=$(tileinspect metadata -t "${TILE}" | yq -r .product_version)

    if ! om upload-product -p "${TILE}" ; then
        echo "Failed to upload product ${TILE}" >&2
        return 1
    fi

    if ! om stage-product --product-name "${PRODUCT_NAME}" --product-version "${PRODUCT_VERSION}" ; then
        echo "Failed to stage version ${PRODUCT_VERSION} of ${PRODUCT_NAME}" >&2
        return 1
    fi

    upload_and_assign_stemcells.sh "$(om curl -s -p /api/v0/stemcell_assignments | jq -r .stemcell_library[0].infrastructure)"

    build-tile-config.sh "${PRODUCT_NAME}" "${TILE_CONFIG}" > config.json

    if ! om configure-product --config ./config.json ; then
        echo "Failed to configure product ${PRODUCT_NAME}" >&2
        return 1
    fi

    rm config.json

    if ! om apply-changes ; then 
        echo "Failed to apply changes" >&2
        return 1
    fi
}

if [ "$#" -lt 2 ]; then    
    usage
    exit 1
fi

install_tile "$1" "$2"
