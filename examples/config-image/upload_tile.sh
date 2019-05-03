#!/bin/bash
ENV_FILE=$1
CRED_FILE=$2
PRODUCT_NAME=$3
PRODUCT_VERSION=$4
shift 4

ENV_NAME="$(jq -r '.name' $ENV_FILE)"

if [[ -z $ENV_FILE ]]; then
    echo "no config file provided"
    exit 1
fi

if [[ -z $CRED_FILE ]]; then
    echo "no cred file provided"
    exit 1
fi

if [[ -z $PRODUCT_NAME ]]; then
    echo "no product name provided"
    exit 1
fi

if [[ -z $PRODUCT_VERSION ]]; then
    echo "no product version provided"
    exit 1
fi

set -x
ENV_HOST="$(jq -r '.paver_paving_output.ops_manager_dns.value' $ENV_FILE)"
export OM_USERNAME="$(jq -r '.username' $CRED_FILE)"
export OM_PASSWORD="$(jq -r '.password' $CRED_FILE)"
export PIVNET_TOKEN="$(jq -r '.pivnet_token' $CRED_FILE)"

marman download-tile -n $PRODUCT_NAME -v $PRODUCT_VERSION
om -k -t $ENV_HOST upload-product -p ./*.pivotal 
