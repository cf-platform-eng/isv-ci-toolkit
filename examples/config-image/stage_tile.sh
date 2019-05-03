#!/bin/bash
ENV_FILE=$1
CRED_FILE=$2
PRODUCT_NAME=$3
PRODUCT_VERSION=$4
shift
shift
shift
shift

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
    echo "no product name provided"
    exit 1
fi

set -x 
ENV_HOST="$(jq -r '.paver_paving_output.ops_manager_dns.value' $ENV_FILE)"
export OM_USERNAME="$(jq -r '.username' $CRED_FILE)"
export OM_PASSWORD="$(jq -r '.password' $CRED_FILE)"

om -k -t $ENV_HOST stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION
