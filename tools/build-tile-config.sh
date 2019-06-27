#!/usr/bin/env bash

set -ueo pipefail

usage() {
    echo "usage: build-tole-config.sh <product name> <config.yml>"
}

function build_tile_config {

  PRODUCT_NAME=$1
  CONFIG_YML=$2

  if ! CLOUD_CONFIG=$(om curl --path /api/v0/deployed/cloud_config 2> /dev/null) ; then
    echo "Failed to get cloud_config from OpsManager" >&2
    return 1
  fi
  NETWORK=$(echo "${CLOUD_CONFIG}" | jq -r .cloud_config.networks[].name | grep services)
  AZS=$(echo "${CLOUD_CONFIG}" | jq -c '[.cloud_config.azs[] | {name}]')
  AZ0=$(echo "${AZS}" | jq -r .[0].name)

  VMS_COUNT=$(echo "$CLOUD_CONFIG" | jq '[.cloud_config.vm_types[].name] | length' )
  echo "${VMS_COUNT}" >&3
  VM_INDEX=$((VMS_COUNT/2))
  VM_NAME=$(echo "${CLOUD_CONFIG}" | jq -r [.cloud_config.vm_types[].name]["${VM_INDEX}"])

  DISK_COUNT=$(echo "$CLOUD_CONFIG" | jq '[.cloud_config.disk_types[].name] | length' )
  DISK_INDEX=$((DISK_COUNT/2))
  DISK_NAME=$(echo "${CLOUD_CONFIG}" | jq -r [.cloud_config.disk_types[].name]["${DISK_INDEX}"])

  cat <<EOF | sed "s/\"{vm_type}\"/${VM_NAME}/g" | sed "s/{disk_type}/${DISK_NAME}/g" | sed "s/\"{az}\"/${AZ0}/g"
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

  < "${CONFIG_YML}" sed "s/\"{vm_type}\"/${VM_NAME}/g" | sed "s/{disk_type}/${DISK_NAME}/g" | sed "s/\"{az}\"/${AZ0}/g"
}

if [ "$#" -lt 2 ]; then    
    usage
    exit 1
fi

build_tile_config "$1" "$2"
