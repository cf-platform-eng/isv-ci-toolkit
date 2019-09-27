#!/bin/bash

set -xe

needs check

iaas=$(jq -r '.iaas' /input/environment.json)

# shellcheck disable=SC1091
UPGRADE=true . setup_om.sh /input/environment.json /input/credentials.json

# Set up PivNet token
PIVNET_TOKEN="$(jq -r '.pivnet_token' /input/credentials.json)"
export PIVNET_TOKEN

# Set up IDP
PASSWORD="$(jq -r '.password' /input/credentials.json)"
om -k configure-authentication --decryption-passphrase "$PASSWORD"

# Configure the director
build_configure_bosh_json.sh /input/environment.json /input/credentials.json > /tmp/director-config.json
om -k configure-director --config /tmp/director-config.json

if [[ "${SKIP_TILE_UPLOAD}" != "true" ]] ; then
    marman download-srt --version "${PRODUCT_VERSION}"
    om -k upload-product --product ./*.pivotal
    om -k stage-product --product-name cf --product-version "${PRODUCT_VERSION}"
    rm ./*.pivotal
fi

# Configure
build_configure_product_json.sh /input/environment.json "/input/elastic-runtime.srt.${iaas}.json" "$STARTING_PCF_VERSION" "$PRODUCT_VERSION" > /tmp/product-config.json
jq '. + {"resource-config": .resource_config} | del(.resource_config) + {"network-properties": .network} | del(.network) + {"product-properties": .properties} | del(.properties)' /tmp/product-config.json > /tmp/product-config-new-schema.json
om -k configure-product --config /tmp/product-config-new-schema.json --ops-file /input/add-cf.yml

if [ "${iaas}" = "gcp" ] ; then
    upload_and_assign_stemcells.sh google
else
    upload_and_assign_stemcells.sh "${iaas}"
fi

# Deploy
if [[ "${SKIP_APPLY_CHANGES}" != "true" ]] ; then
    om -k apply-changes
fi

om -k export-installation -o /tmp/installation.zip

# shellcheck disable=SC1091
. setup_om.sh /input/environment.json /input/credentials.json

om -k -d "$OM_PASSWORD" import-installation -i /tmp/installation.zip

if [[ "${SKIP_TILE_UPLOAD}" != "true" ]] ; then
    marman download-srt --version "${UPGRADED_PRODUCT_VERSION}"
    om -k upload-product --product ./*.pivotal
    om -k stage-product --product-name cf --product-version "${UPGRADED_PRODUCT_VERSION}"
    rm ./*.pivotal
fi

# Configure
build_configure_product_json.sh /input/environment.json "/input/elastic-runtime.srt.${iaas}.json" "$UPGRADED_PCF_VERSION" "$UPGRADED_PRODUCT_VERSION" > /tmp/product-config.json
jq '. + {"resource-config": .resource_config} | del(.resource_config) + {"network-properties": .network} | del(.network) + {"product-properties": .properties} | del(.properties)' /tmp/product-config.json > /tmp/product-config-new-schema.json
om -k configure-product --config /tmp/product-config-new-schema.json --ops-file /input/add-cf.yml

if [ "${iaas}" = "gcp" ] ; then
    upload_and_assign_stemcells.sh google
else
    upload_and_assign_stemcells.sh "${iaas}"
fi

# Deploy
if [[ "${SKIP_APPLY_CHANGES}" != "true" ]] ; then
    om -k apply-changes
fi
