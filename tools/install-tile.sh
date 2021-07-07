#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: install-tile.sh <tile> <config.yml> [<full deploy>]"
    echo "    tile - path to a .pivotal file"
    echo "    config.yml - path to tile configuration"
    echo "    full deploy - if true, deploys all products, otherwise only deploys this tile (default false)"
}

install_tile() {
    TILE=$1             # TODO TILE_PATH
    TILE_CONFIG=$2      # TODO TILE_CONFIG_PATH
    USE_FULL_DEPLOY=$3

    PRODUCT_NAME=$(tileinspect metadata --tile "${TILE}" --format json | jq -r .name)
    PRODUCT_VERSION=$(tileinspect metadata --tile "${TILE}" --format json | jq -r .product_version)

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

    generate-config-for-tile.sh "${TILE}" "${TILE_CONFIG}" > "${GENERATED_CONFIG_PATH}"
    compare-staged-config.sh "${PRODUCT_NAME}" "${GENERATED_CONFIG_PATH}"

    stemcells="$(om curl --path /api/v0/stemcell_assignments | jq -rc .stemcell_library[])"
    # shellcheck disable=SC2091
    for STEMCELL in $stemcells; do
      FULL_NAME=$(echo "$STEMCELL" | jq '. | "\(.infrastructure)-\(.hypervisor)-\(.os)"')
      VERSION="$(echo "$STEMCELL" | jq '. | (.version)')"

      mrlog dependency --type stemcell --name "${FULL_NAME}" --version "${VERSION}" --metadata "${STEMCELL}"
    done

    upload_and_assign_stemcells.sh "$(om curl -s -p /api/v0/stemcell_assignments | jq -r .stemcell_library[0].infrastructure)"

    if ! om configure-product --config "${GENERATED_CONFIG_PATH}" ; then
        echo "Failed to configure product ${PRODUCT_NAME}" >&2
        echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
        return 1
    fi

    rm "${GENERATED_CONFIG_PATH}"

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
}

if [ "$#" -lt 2 ]; then
    usage
    exit 1
fi

install_tile "$1" "$2" "${3:-false}"
