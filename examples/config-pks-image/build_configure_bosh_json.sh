#!/bin/bash
ENV_FILE=$1
CREDS_FILE=$2
IAAS=$3
ENV_NAME="$(jq -r '.name' $ENV_FILE)"

if [[ -z $ENV_FILE ]]; then
    echo "no config file provided"
    exit 1
fi

if [[ -z $CREDS_FILE ]]; then
    echo "no creds file provided"
    exit 1
fi

set -x
network_name=$(jq -r '.paver_iaas_specific_output.network_name' $ENV_FILE)
management_subnet_name=$(jq -r '.paver_iaas_specific_output.management_subnet_name' $ENV_FILE)
pks_subnet_name=$(jq -r '.paver_paving_output.pks_subnet_name.value' $ENV_FILE)
services_subnet_name=$(jq -r '.paver_iaas_specific_output.services_subnet_name' $ENV_FILE)

OPSMAN_NETWORK_NAME="$management_subnet_name"
OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name"
PKS_IAAS_IDENTIFIER="$network_name/$pks_subnet_name"
SERVICES_IAAS_IDENTIFIER="$network_name/$services_subnet_name"

PUBLIC_KEY="$(jq -r '.paver_iaas_specific_output.ops_manager_ssh_public_key' $ENV_FILE)"
PRIVATE_KEY="$(jq -r '.paver_paving_output.ops_manager_ssh_private_key.value' $ENV_FILE)"

region=$(jq -r '.paver_iaas_specific_output.region' $ENV_FILE)
project=$(jq -r '.paver_iaas_specific_output.project' $ENV_FILE)
network_name=$(jq -r '.paver_iaas_specific_output.network_name' $ENV_FILE)
management_subnet_name=$(jq -r '.paver_iaas_specific_output.management_subnet_name' $ENV_FILE)
service_account_email=$(jq -r '.paver_iaas_specific_output.service_account_email' $ENV_FILE)

export SERVICE_ACCOUNT_KEY=$(jq -r '.service_account_key | tostring' $CREDS_FILE)

SERVICES_NETWORK_NAME=$(jq -r '.paver_iaas_specific_output.services_subnet_name' $ENV_FILE)
OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name/$region"
PKS_IAAS_IDENTIFIER="$network_name/$pks_subnet_name/$region"
SERVICES_IAAS_IDENTIFIER="$network_name/$services_subnet_name/$region"

NETWORK_AZS="$(jq -c -M '.paver_iaas_specific_output.azs | .[] |= { "name": .}' $ENV_FILE)"

read -d '' iaas_jq_input << EOF
{
  "az-configuration": $NETWORK_AZS,
  "properties-configuration": {
	  "iaas_configuration": {
	    "project": "$project",
	    "default_deployment_tag": "$ENV_NAME",
	    "associated_service_account": "$service_account_email",
            "auth_json": env.SERVICE_ACCOUNT_KEY,
	  },
	  "director_configuration": {
	    "ntp_servers_string": "us.pool.ntp.org",
	    "post_deploy_enabled": true,
	    "keep_unreachable_vms": false,
	    "identification_tags_string": "gips-install:$ENV_NAME"
	  },
	  "security_configuration": {
	    "trusted_certificates": null,
	    "generate_vm_passwords": false
	  },
  },
  "networks-configuration": {
    "icmp_checks_enabled": false,
    "networks": [
      {
        "name": "$OPSMAN_NETWORK_NAME",
        "subnets": [
          {
            "iaas_identifier": "$OPS_MANAGER_IAAS_IDENTIFIER",
            "cidr": .paver_paving_output.management_subnet_cidrs.value[0],
            "reserved_ip_ranges": "10.0.0.0-10.0.0.5",
            "dns": "169.254.169.254",
            "gateway": .paver_iaas_specific_output.management_subnet_gateway,
            "availability_zone_names": .paver_iaas_specific_output.azs
          }
        ]
      },
      {
        "name": .paver_paving_output.pks_subnet_name.value,
        "subnets": [
          {
            "iaas_identifier": "$PKS_IAAS_IDENTIFIER",
            "cidr": .paver_paving_output.pks_subnet_cidrs.value[0],
            "reserved_ip_ranges": "10.0.10.0-10.0.10.4,10.0.10.254",
            "dns": "169.254.169.254",
            "gateway": .paver_paving_output.pks_subnet_gateway.value,
            "availability_zone_names": .paver_iaas_specific_output.azs
          }
        ]
      },
      {
        "name": .paver_iaas_specific_output.services_subnet_name,
        "service_network": true,
        "subnets": [
          {
            "iaas_identifier": "$SERVICES_IAAS_IDENTIFIER",
            "cidr": .paver_paving_output.pks_services_subnet_cidrs.value[0],
            "reserved_ip_ranges": "10.0.11.0-10.0.11.4,10.0.11.254",
            "dns": "169.254.169.254",
            "gateway": .paver_iaas_specific_output.services_subnet_gateway,
            "availability_zone_names": .paver_iaas_specific_output.azs
          }
        ]
      }
    ]
  },
  "network-assignment": {
    "singleton_availability_zone": {"name": .paver_iaas_specific_output.azs[0] },
    "network": {"name": "$OPSMAN_NETWORK_NAME" }
  },
  "resource-configuration": {
    "compilation": {
      "internet_connected": true,
      "instance_type": {
        "id": "xlarge.disk"
      }
    },
    "director": {
      "internet_connected": true,
      "persistent_disk": {
        "size_mb": "102400"
      }
    }
  }
}
EOF

iaas_configuration=$(jq -r ". | $iaas_jq_input" $ENV_FILE)

echo $iaas_configuration
exit 0
