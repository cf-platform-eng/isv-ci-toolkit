#!/bin/bash

set -xe
./set_up_idp.sh /input/environment.json /input/credentials.json
./build_configure_bosh_json.sh /input/environment.json /input/credentials.json > /tmp/director-config.json
./run_om.sh configure-director /input/environment.json /input/credentials.json /tmp/director-config.json
./upload_tile.sh /input/environment.json /input/credentials.json $PRODUCT_NAME $PRODUCT_VERSION
./stage_tile.sh /input/environment.json /input/credentials.json /input/elastic-runtime.srt.azure.json cf $PRODUCT_VERSION
./build_configure_product_json.sh /input/environment.json /input/elastic-runtime.srt.azure.json $PCF_VERSION $PRODUCT_VERSION > /tmp/product-config.json
cat /tmp/product-config.json | jq '. + {"resource-config": .resource_config} | del(.resource_config) + {"network-properties": .network} | del(.network) + {"product-properties": .properties} | del(.properties)' > /tmp/product-config-new-schema.json
./run_om.sh configure-product /input/environment.json /input/credentials.json /tmp/product-config-new-schema.json -o /input/add-cf.yml
./upload_and_assign_stemcells.sh /input/environment.json /input/credentials.json azure
