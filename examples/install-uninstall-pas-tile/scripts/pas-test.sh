#!/usr/bin/env bash

set -ueo pipefail

PRODUCT_NAME=$(tileinspect metadata -t "/tile/$TILE_NAME" | yq -r .name)
PRODUCT_VERSION=$(tileinspect metadata -t "/tile/$TILE_NAME" | yq -r .product_version)

om upload-product -p "/tile/${TILE_NAME}"
om stage-product --product-name "${PRODUCT_NAME}" --product-version "${PRODUCT_VERSION}"

upload_and_assign_stemcells.sh "$(om curl -s -p /api/v0/stemcell_assignments | jq -r .stemcell_library[0].infrastructure)"

build_tile_config.sh "${PRODUCT_NAME}" "/tile-config/${TILE_CONFIG}" > config.json

om configure-product --config ./config.json

rm config.json

om apply-changes

om unstage-product -p "${PRODUCT_NAME}"

om apply-changes

om delete-product -p "${PRODUCT_NAME}" -v "${PRODUCT_VERSION}"
