#!/usr/bin/env bash

ENV_FILE=$1
CRED_FILE=$2

if [[ -z $ENV_FILE ]]; then
    echo "no environment file provided"
    exit 1
fi

if [[ -z $CRED_FILE ]]; then
    echo "no cred file provided"
    exit 1
fi

export OM_TARGET="$(jq -r '.paver_paving_output.ops_manager_dns.value' $ENV_FILE)"
export OM_USERNAME="$(jq -r '.username' $CRED_FILE)"
export OM_PASSWORD="$(jq -r '.password' $CRED_FILE)"
export OM_SKIP_SSL_VALIDATION=true
