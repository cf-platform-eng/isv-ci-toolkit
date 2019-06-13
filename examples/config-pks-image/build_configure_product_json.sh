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
network_name=$(jq -r '.paver_iaas_specific_output.network_name' $ENV_FILE)
management_subnet_name=$(jq -r '.paver_iaas_specific_output.management_subnet_name' $ENV_FILE)
pks_subnet_name=$(jq -r '.paver_paving_output.pks_subnet_name.value' $ENV_FILE)
services_subnet_name=$(jq -r '.paver_iaas_specific_output.services_subnet_name' $ENV_FILE)

export NETWORK_NAME="$network_name"
export OPSMAN_NETWORK_NAME="$management_subnet_name"
export PKS_NETWORK_NAME="$pks_subnet_name"
export SERVICES_NETWORK_NAME="$services_subnet_name"
export OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name"
export PKS_IAAS_IDENTIFIER="$network_name/$pks_subnet_name"
export SERVICES_IAAS_IDENTIFIER="$network_name/$services_subnet_name"
export SYSTEM_DOMAIN=$(jq -r '.paver_paving_output.sys_domain.value' $ENV_FILE)
export APPS_DOMAIN=$(jq -r '.paver_paving_output.apps_domain.value' $ENV_FILE)
export ERT_DOMAIN_KEY=$(jq '.paver_paving_output.ssl_private_key.value' $ENV_FILE)
export ERT_DOMAIN_KEY="${ERT_DOMAIN_KEY:1:${#ERT_DOMAIN_KEY}-2}"
export ERT_DOMAIN_CERT=$(jq '.paver_paving_output.ssl_cert.value' $ENV_FILE)
export ERT_DOMAIN_CERT="${ERT_DOMAIN_CERT:1:${#ERT_DOMAIN_CERT}-2}"
export WEB_LB=$(jq -r '.paver_iaas_specific_output.web_lb_name' $ENV_FILE)
export PKS_LB_BACKEND_NAME=$(jq -r '.paver_paving_output.pks_lb_backend_name.value' $ENV_FILE)
export AZ_NAME=$(jq -r '.paver_iaas_specific_output.azs[0]' $ENV_FILE)
export OTHER_AZS=$(jq -r '.paver_iaas_specific_output.azs | map({name: .})' $ENV_FILE)
export ERT_NETWORK_NAME=$pas_subnet_name
export JUMPBOX_PRIVATE_IP=""
export CREDHUB_ENCRYPTION_PASSWORD="12345678901234567890"
export MASTER_PRIVATE_KEY_ID=$(jq -r '.paver_paving_output.pks_master_node_service_account_key.value | fromjson.private_key_id' $ENV_FILE)
export WORKER_PRIVATE_KEY_ID=$(jq -r '.paver_paving_output.pks_worker_node_service_account_key.value | fromjson.private_key_id' $ENV_FILE)
export PROJECT_ID=$(jq -r '.paver_iaas_specific_output.project' $ENV_FILE)
export PKS_API_ENDPOINT=$(jq -r '.paver_paving_output.pks_api_endpoint.value' $ENV_FILE)

export IAAS=$(jq -r '.iaas' $ENV_FILE)
if [[ "$IAAS" == "azure" ]]; then
	AZ_NAME="zone-1"
	OTHER_AZS='[{"name": "zone-1"},{"name": "zone-2"},{"name": "zone-3"}]'
fi

product_configuration="$(./retrieve_tile_configuration.sh $PRODUCT_FILE $PCF_VERSION $PRODUCT_VERSION | envsubst)"
echo "$product_configuration"
exit 0
