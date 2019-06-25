#!/usr/bin/env bash

set -ueo pipefail

function build_tile_config {

  CLOUD_CONFIG=$(om -k curl --path /api/v0/deployed/cloud_config 2> /dev/null)
  NETWORK=$(echo ${CLOUD_CONFIG} | jq -r .cloud_config.networks[].name | grep services)
  AZS=$(echo ${CLOUD_CONFIG} | jq '[.cloud_config.azs[] | {name}]' | tr '\n' ' ')
  AZ0=$(echo ${AZS} | jq -r .[0].name)

  VMS_COUNT=$(echo $CLOUD_CONFIG | jq '[.cloud_config.vm_types[].name] | length' )
  let "VM_INDEX = ${VMS_COUNT} / 2"
  VM_NAME=$(echo ${CLOUD_CONFIG} | jq -r [.cloud_config.vm_types[].name][${VM_INDEX}])

  DISK_COUNT=$(echo $CLOUD_CONFIG | jq '[.cloud_config.disk_types[].name] | length' )
  let "DISK_INDEX = ${DISK_COUNT} / 2"
  DISK_NAME=$(echo ${CLOUD_CONFIG} | jq -r [.cloud_config.disk_types[].name][${DISK_INDEX}])

  cat <<EOF > ./config.yml
product-name: ${PRODUCT_NAME}
network-properties:
  network:
    name: ${NETWORK}
  service_network:
    name: ${NETWORK}
  other_availability_zones: ${AZS}
  singleton_availability_zone:
    name: ${AZ0}
EOF

  cat /tile-config/${TILE_CONFIG} | sed "s/\"{vm_type}\"/${VM_NAME}/g" | sed "s/{disk_type}/${DISK_NAME}/g" | sed "s/\"{az}\"/${AZ0}/g" >> ./config.yml
}

PRODUCT_NAME=$(tileinspect metadata -t /tile/$TILE_NAME | yq -r .name)
PRODUCT_VERSION=$(tileinspect metadata -t /tile/$TILE_NAME | yq -r .product_version)

om -k upload-product -p /tile/${TILE_NAME}
om -k stage-product --product-name ${PRODUCT_NAME} --product-version ${PRODUCT_VERSION}

upload_and_assign_stemcells.sh $(om -k curl -s -p /api/v0/stemcell_assignments | jq -r .stemcell_library[0].infrastructure)

build_tile_config

om -k configure-product --config ./config.yml

om -k apply-changes

om -k unstage-product -p ${PRODUCT_NAME}

om -k apply-changes
om -k delete-product -p ${PRODUCT_NAME} -v ${PRODUCT_VERSION}