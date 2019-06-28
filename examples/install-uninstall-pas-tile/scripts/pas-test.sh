#!/usr/bin/env bash

set -ueo pipefail

PRODUCT_NAME=$(tileinspect metadata -t /tile/$TILE_NAME | yq -r .name)
PRODUCT_VERSION=$(tileinspect metadata -t /tile/$TILE_NAME | yq -r .product_version)

om -k upload-product -p /tile/${TILE_NAME}
om -k stage-product --product-name ${PRODUCT_NAME} --product-version ${PRODUCT_VERSION}

upload_and_assign_stemcells.sh $(om -k curl -s -p /api/v0/stemcell_assignments | jq -r .stemcell_library[0].infrastructure)

build_tile_config.sh ${PRODUCT_NAME} /tile-config/${TILE_CONFIG} > config.json

om -k configure-product --config ./config.json

om -k apply-changes

om -k unstage-product -p ${PRODUCT_NAME}

om -k apply-changes
om -k delete-product -p ${PRODUCT_NAME} -v ${PRODUCT_VERSION}