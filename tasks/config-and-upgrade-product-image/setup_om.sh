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

if [[ "$UPGRADE" == "true" ]]; then
  OM_TARGET="$(jq -r '.paver_paving_output.optional_ops_manager_dns.value // empty' "$ENV_FILE")"
else
  OM_TARGET="$(jq -r '.paver_paving_output.ops_manager_dns.value // empty' "$ENV_FILE")"
fi
OM_USERNAME="$(jq -r '.username // empty' "$CRED_FILE")"
OM_PASSWORD="$(jq -r '.password // empty' "$CRED_FILE")"

if [[ -z $OM_TARGET ]]; then
    echo "no optional ops manager provided"
    exit 1
fi

if [[ -z $OM_USERNAME ]]; then
    echo "no ops manager username provided"
    exit 1
fi

if [[ -z $OM_PASSWORD ]]; then
    echo "no ops manager password provided"
    exit 1
fi

export OM_TARGET
export OM_USERNAME
export OM_PASSWORD
export OM_SKIP_SSL_VALIDATION=true
