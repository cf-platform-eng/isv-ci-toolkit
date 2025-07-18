#!/usr/bin/env bash
# shellcheck disable=SC2016

set -ueo pipefail

usage() {
    echo "usage: generate-config-for-tile.sh <tile> <config.yml|config.json>"
}

function gen_tile_config {
    TILE_PATH=$1
    CONFIG_FILE=$2

    if ! PRODUCT_NAME=$(tileinspect metadata --tile "${TILE_PATH}" --format json | jq -r .name); then
        echo "Failed to get metadata from ${TILE_PATH}"
        return 1
    fi
    if ! COUNT_JOB_TYPES=$(tileinspect metadata --tile "${TILE_PATH}" --format json | jq -r '.job_types | length'); then
        echo "Failed to get metadata from ${TILE_PATH}"
        return 1
    fi

    if ! CLOUD_CONFIG=$(om curl --path /api/v0/deployed/cloud_config 2> /dev/null) ; then
        echo "Failed to get cloud_config from OpsManager" >&2
        return 1
    fi

    if ! NETWORK=$(echo "${CLOUD_CONFIG}" | jq -r '.cloud_config.networks[] | select(.name | contains("services")) | .name') ; then
        echo "OpsManager cloud config has no networks" >&2
        return 1
    fi
    
    if [ -z "$NETWORK" ]; then
        # If no services network found, try to use the first available network
        if ! NETWORK=$(echo "${CLOUD_CONFIG}" | jq -r '.cloud_config.networks[0].name') ; then
            echo "OpsManager cloud config has no networks" >&2
            return 1
        fi
        echo "Warning: No network with 'services' in name found, using first available network: ${NETWORK}" >&2
    fi

    if ! AZS=$(echo "${CLOUD_CONFIG}" | jq -c '[.cloud_config.azs[] | {name}]') ; then
        echo "OpsManager cloud config has no availability zones" >&2
        return 1
    fi
    AZ0=$(echo "${AZS}" | jq -r .[0].name)

    if ! VMS_COUNT=$(echo "$CLOUD_CONFIG" | jq '[.cloud_config.vm_types[].name] | length' ) ; then
        echo "OpsManager cloud config has no vm types" >&2
        return 1
    fi
    VM_INDEX=$((VMS_COUNT/2))
    VM_NAME=$(echo "${CLOUD_CONFIG}" | jq -r [.cloud_config.vm_types[].name]["${VM_INDEX}"])

    if ! DISK_COUNT=$(echo "$CLOUD_CONFIG" | jq '[.cloud_config.disk_types[].name] | length' ) ; then
        echo "OpsManager cloud config has no disk types" >&2
        return 1
    fi

    DISK_INDEX=$((DISK_COUNT/2))
    DISK_NAME=$(echo "${CLOUD_CONFIG}" | jq -r [.cloud_config.disk_types[].name]["${DISK_INDEX}"])

    if [ "${COUNT_JOB_TYPES:-0}" -eq "0" ]; then 
        jq --compact-output --arg productName "${PRODUCT_NAME}" \
            '.["product-name"] = $productName' \
            "${CONFIG_FILE}" \
            | sed "s/{vm_type}/${VM_NAME}/g" \
            | sed "s/{disk_type}/${DISK_NAME}/g" \
            | sed "s/{az}/${AZ0}/g"
    else
        jq --compact-output --arg productName "${PRODUCT_NAME}" \
            --arg network "${NETWORK}" \
            --arg az "${AZ0}" \
            --argjson azs "${AZS}" \
            '.["product-name"] = $productName | .["network-properties"].network.name = $network | .["network-properties"].service_network.name = $network | .["network-properties"].singleton_availability_zone.name = $az | .["network-properties"].other_availability_zones = $azs' \
            "${CONFIG_FILE}" \
            | sed "s/{vm_type}/${VM_NAME}/g" \
            | sed "s/{disk_type}/${DISK_NAME}/g" \
            | sed "s/{az}/${AZ0}/g"
    fi
}

if [ "$#" -lt 2 ]; then
    usage
    exit 1
fi

gen_tile_config "$1" "$2"