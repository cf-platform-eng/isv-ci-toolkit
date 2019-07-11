#!/bin/bash
ENV_FILE=$1
PRODUCT_FILE=$2
PCF_VERSION=$3
PRODUCT_VERSION=$4
ENV_NAME="$(jq -r '.name' $ENV_FILE)"

if [[ -z $ENV_FILE ]]; then
    echo "no config file provided"
    exit 1
fi

if [[ -z $PRODUCT_FILE ]]; then
    echo "no product file provided"
    exit 1
fi

set -x
iaas=$(jq -r '.iaas' $ENV_FILE)
network_name=$(jq -r '.paver_iaas_specific_output.network_name' $ENV_FILE)
management_subnet_name=$(jq -r '.paver_iaas_specific_output.management_subnet_name' $ENV_FILE)
pas_subnet_name=$(jq -r '.paver_iaas_specific_output.pas_subnet_name' $ENV_FILE)
services_subnet_name=$(jq -r '.paver_iaas_specific_output.services_subnet_name' $ENV_FILE)

export OPSMAN_NETWORK_NAME="$management_subnet_name"
export OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name"
export PAS_IAAS_IDENTIFIER="$network_name/$pas_subnet_name"
export SERVICES_IAAS_IDENTIFIER="$network_name/$services_subnet_name"
export SYSTEM_DOMAIN=$(jq -r '.paver_paving_output.sys_domain.value' $ENV_FILE)
export APPS_DOMAIN=$(jq -r '.paver_paving_output.apps_domain.value' $ENV_FILE)
export ERT_DOMAIN_KEY=$(jq '.paver_paving_output.ssl_private_key.value' $ENV_FILE)
export ERT_DOMAIN_KEY="${ERT_DOMAIN_KEY:1:${#ERT_DOMAIN_KEY}-2}"
export ERT_DOMAIN_CERT=$(jq '.paver_paving_output.ssl_cert.value' $ENV_FILE)
export ERT_DOMAIN_CERT="${ERT_DOMAIN_CERT:1:${#ERT_DOMAIN_CERT}-2}"
export ERT_NETWORK_NAME=$pas_subnet_name
export JUMPBOX_PRIVATE_IP=""
export CREDHUB_ENCRYPTION_PASSWORD="12345678901234567890"

if [ "${iaas}" = "azure" ] ; then
    export AZ_NAME="zone-1"
    # export OTHER_AZS="[\"zone-1\"]"
    export SSH_LB="???"
    export WEB_LB=$(jq -r '.paver_iaas_specific_output.web_lb_name' $ENV_FILE)
fi

if [ "${iaas}" = "gcp" ] ; then
    export AZ_NAME=$(jq -r '.paver_iaas_specific_output.azs[0]' $ENV_FILE)
    # export OTHER_AZS=$(jq -r '.paver_iaas_specific_output.azs | map({name: .})' $ENV_FILE)
    export SSH_LB=tcp:$(jq -r '.paver_paving_output.ssh_lb_name.value' $ENV_FILE)
    export WEB_LB=http:$(jq -r '.paver_paving_output.web_lb_name.value' $ENV_FILE)
fi

product_configuration="$(./retrieve_tile_configuration.sh $PRODUCT_FILE $PCF_VERSION $PRODUCT_VERSION | envsubst)"
echo "$product_configuration"
exit 0
