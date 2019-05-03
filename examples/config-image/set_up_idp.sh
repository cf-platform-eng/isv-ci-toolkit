#!/bin/bash
ENV_FILE=$1
CRED_FILE=$2
ENV_NAME="$(jq -r '.name' $ENV_FILE)"

if [[ -z $ENV_FILE ]]; then
    echo "no environment file provided"
    exit 1
fi

if [[ -z $CRED_FILE ]]; then
    echo "no cred file provided"
    exit 1
fi

set -x
ENV_HOST="$(jq -r '.paver_paving_output.ops_manager_dns.value' $ENV_FILE)"
USERNAME="$(jq -r '.username' $CRED_FILE)"
PASSWORD="$(jq -r '.password' $CRED_FILE)"

om -k -t $ENV_HOST configure-authentication -u "$USERNAME" -p "$PASSWORD" -dp "$PASSWORD"
