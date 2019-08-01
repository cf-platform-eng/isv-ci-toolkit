#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: install-tile.sh <tile> <config.yml> [<selective deploy>]"
    echo "    tile - path to a .pivotal file"
    echo "    config.yml - path to tile configuration"
    echo "    selective deploy - if true, only deploy this tile (default false)"
}

install_tile() {
    TILE=$1             # TODO TILE_PATH
    TILE_CONFIG=$2      # TODO TILE_CONFIG_PATH
    USE_SELECTIVE_DEPLOY=$3

    PRODUCT_NAME=$(tileinspect metadata -t "${TILE}" | yq -r .name)
    PRODUCT_VERSION=$(tileinspect metadata -t "${TILE}" | yq -r .product_version)

    GENERATED_CONFIG_PATH="${PWD}/config.json"

    if ! om upload-product --product "${TILE}" ; then
        echo "Failed to upload product ${TILE}" >&2
        echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
        return 1
    fi

    if ! om stage-product --product-name "${PRODUCT_NAME}" --product-version "${PRODUCT_VERSION}" ; then
        echo "Failed to stage version ${PRODUCT_VERSION} of ${PRODUCT_NAME}" >&2
        echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
        return 1
    fi

    build-tile-config.sh "${PRODUCT_NAME}" "${TILE_CONFIG}" > "${GENERATED_CONFIG_PATH}"
    compare-staged-config.sh "${PRODUCT_NAME}" "${GENERATED_CONFIG_PATH}"

    upload_and_assign_stemcells.sh "$(om curl -s -p /api/v0/stemcell_assignments | jq -r .stemcell_library[0].infrastructure)"


    stemcells="$(om curl --path /api/v0/stemcell_assignments | jq .stemcell_library)"
    $(echo -e "${stemcells}" | jq -r '.[] | "mrlog dependency --name \(.infrastructure)-\(.hypervisor)-\(.os) --version \(.version)"')

    if ! om configure-product --config ./config.json ; then
        echo "Failed to configure product ${PRODUCT_NAME}" >&2
        echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
        return 1
    fi

    rm config.json

    SELECTIVE_DEPLOY_ARG=""
    if [ "${USE_SELECTIVE_DEPLOY}" == "true" ] ; then
        SELECTIVE_DEPLOY_ARG=(--product-name "${PRODUCT_NAME}")
    fi

    if ! om apply-changes ${SELECTIVE_DEPLOY_ARG[*]} ; then
        echo "Failed to apply changes" >&2
        echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
        return 1
    fi
}

if [ "$#" -lt 2 ]; then
    usage
    exit 1
fi

install_tile "$1" "$2" "${3:-false}"
