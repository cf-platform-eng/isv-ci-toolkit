#!/bin/bash
ENV_FILE=$1
PRODUCT_FILE=$2
PCF_VERSION=$3
PRODUCT_VERSION=$4

if [[ -z $ENV_FILE ]]; then
    echo "no config file provided"
    exit 1
fi

if [[ -z $PRODUCT_FILE ]]; then
    echo "no product file provided"
    exit 1
fi

set -x
iaas=$(jq -r '.iaas' "$ENV_FILE")
network_name=$(jq -r '.paver_iaas_specific_output.network_name' "$ENV_FILE")
management_subnet_name=$(jq -r '.paver_iaas_specific_output.management_subnet_name' "$ENV_FILE")
pas_subnet_name=$(jq -r '.paver_iaas_specific_output.pas_subnet_name' "$ENV_FILE")
services_subnet_name=$(jq -r '.paver_iaas_specific_output.services_subnet_name' "$ENV_FILE")

SYSTEM_DOMAIN=$(jq -r '.paver_paving_output.sys_domain.value' "$ENV_FILE")
APPS_DOMAIN=$(jq -r '.paver_paving_output.apps_domain.value' "$ENV_FILE")
ERT_DOMAIN_KEY=$(jq '.paver_paving_output.ssl_private_key.value' "$ENV_FILE")
ERT_DOMAIN_KEY="${ERT_DOMAIN_KEY:1:${#ERT_DOMAIN_KEY}-2}"
ERT_DOMAIN_CERT=$(jq '.paver_paving_output.ssl_cert.value' "$ENV_FILE")
ERT_DOMAIN_CERT="${ERT_DOMAIN_CERT:1:${#ERT_DOMAIN_CERT}-2}"

export OPSMAN_NETWORK_NAME="$management_subnet_name"
export OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name"
export PAS_IAAS_IDENTIFIER="$network_name/$pas_subnet_name"
export SERVICES_IAAS_IDENTIFIER="$network_name/$services_subnet_name"
export SYSTEM_DOMAIN
export APPS_DOMAIN
export ERT_DOMAIN_KEY
export ERT_DOMAIN_CERT
export ERT_NETWORK_NAME=$pas_subnet_name
export JUMPBOX_PRIVATE_IP=""
export CREDHUB_ENCRYPTION_PASSWORD="12345678901234567890"

if [ "${iaas}" = "azure" ] ; then
    AZ_NAME="zone-1"
    # OTHER_AZS="[\"zone-1\"]"
    SSH_LB=$(jq -r '.paver_paving_output.diego_ssh_lb_name.value' "$ENV_FILE")
    WEB_LB=$(jq -r '.paver_iaas_specific_output.web_lb_name' "$ENV_FILE")
fi

if [ "${iaas}" = "gcp" ] ; then
    AZ_NAME=$(jq -r '.paver_iaas_specific_output.azs[0]' "$ENV_FILE")
    # OTHER_AZS=$(jq -r '.paver_iaas_specific_output.azs | map({name: .})' "$ENV_FILE")
    SSH_LB=tcp:$(jq -r '.paver_paving_output.ssh_lb_name.value' "$ENV_FILE")
    WEB_LB=http:$(jq -r '.paver_paving_output.web_lb_name.value' "$ENV_FILE")
    WS_LB=tcp:$(jq -r '.paver_paving_output.ws_router_pool.value' "$ENV_FILE")
fi

export AZ_NAME
# export OTHER_AZS
export SSH_LB
export WEB_LB
export WS_LB
product_configuration="$(./retrieve_tile_configuration.sh "$PRODUCT_FILE" "$PCF_VERSION" "$PRODUCT_VERSION" | envsubst)"
echo "$product_configuration" | jq .
exit 0
