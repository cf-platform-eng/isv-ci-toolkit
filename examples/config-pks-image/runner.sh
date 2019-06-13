#!/bin/bash

set -xe

# Configure OM environment variables
. ./setup_om.sh /input/environment.json /input/credentials.json

# Set up PivNet token
export PIVNET_TOKEN="$(jq -r '.pivnet_token' /input/credentials.json)"

# Set up IDP
PASSWORD="$(jq -r '.password' /input/credentials.json)"
om -k configure-authentication --decryption-passphrase "$PASSWORD"

# Configure the director
IAAS="$(jq -r '.iaas' /input/environment.json)"
./build_configure_bosh_json.sh /input/environment.json /input/credentials.json $IAAS > /tmp/director-config.json
om -k configure-director --config /tmp/director-config.json

if [[ "${SKIP_TILE_UPLOAD}" != "true" ]] ; then
    marman download-pks -v ${PRODUCT_VERSION}
    om -k upload-product --product ./*.pivotal
    UPLOADED_VERSION=$(tileinspect metadata -t pivotal-container-service-1.4.0-build.31.pivotal -f json | jq -r ".product_version")
    om -k stage-product --product-name pivotal-container-service --product-version ${UPLOADED_VERSION}
fi

# Configure
ENV_NAME=$(jq -r '.name' input/environment.json)
DNS_SUFFIX=$(jq -r '.dns_suffix' input/environment.json)
./build_configure_product_json.sh /input/environment.json /input/pivotal-container-service.gcp.json $PCF_VERSION $PRODUCT_VERSION > /tmp/product-config.json
om -k generate-certificate --domains "*.api.pks.${ENV_NAME}.${DNS_SUFFIX}" > /tmp/api-certificate.json
om -k configure-product --config /tmp/product-config.json --vars-file /tmp/api-certificate.json --ops-file /input/add-pks.yml 

./upload_and_assign_stemcells.sh google
