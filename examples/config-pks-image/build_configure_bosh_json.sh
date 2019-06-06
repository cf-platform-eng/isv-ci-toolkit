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
pas_subnet_name=$(jq -r '.paver_iaas_specific_output.pas_subnet_name' $ENV_FILE)
services_subnet_name=$(jq -r '.paver_iaas_specific_output.services_subnet_name' $ENV_FILE)

OPSMAN_NETWORK_NAME="$management_subnet_name"
OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name"
PAS_IAAS_IDENTIFIER="$network_name/$pas_subnet_name"
SERVICES_IAAS_IDENTIFIER="$network_name/$services_subnet_name"

PUBLIC_KEY="$(jq -r '.paver_iaas_specific_output.ops_manager_ssh_public_key' $ENV_FILE)"
PRIVATE_KEY="$(jq -r '.paver_paving_output.ops_manager_ssh_private_key.value' $ENV_FILE)"


if [[ "gcp" == "$IAAS" ]]; then
    region=$(jq -r '.paver_iaas_specific_output.region' $ENV_FILE)
    project=$(jq -r '.paver_iaas_specific_output.project' $ENV_FILE)
    network_name=$(jq -r '.paver_iaas_specific_output.network_name' $ENV_FILE)
    management_subnet_name=$(jq -r '.paver_iaas_specific_output.management_subnet_name' $ENV_FILE)
    service_account_email=$(jq -r '.paver_iaas_specific_output.service_account_email' $ENV_FILE)

    export SERVICE_ACCOUNT_KEY=$(jq -r '.service_account_key | tostring' $CREDS_FILE)

    SERVICES_NETWORK_NAME=$(jq -r '.paver_iaas_specific_output.services_subnet_name' $ENV_FILE)
    OPS_MANAGER_IAAS_IDENTIFIER="$network_name/$management_subnet_name/$region"
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
        "name": "$SERVICES_NETWORK_NAME",
        "service_network": true,
        "subnets": [
          {
            "iaas_identifier": "$SERVICES_IAAS_IDENTIFIER",
            "cidr": .paver_paving_output.pks_services_subnet_cidrs.value[0],
            "reserved_ip_ranges": "10.0.8.0-10.0.8.4,10.0.8.254",
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
elif [[ "azure" == "$IAAS" ]]; then

SUBSCRIPTION_ID="$(jq -r '.subscription_id' $CREDS_FILE)"
TENANT_ID="$(jq -r '.tenant_id' $CREDS_FILE)"
CLIENT_ID="$(jq -r '.client_id' $CREDS_FILE)"
CLIENT_SECRET="$(jq -r '.client_secret' $CREDS_FILE)"

read -d '' iaas_jq_input << EOF
{
  "networks-configuration": {
    "icmp_checks_enabled": false,
    "networks": [
      {
        "name": .paver_iaas_specific_output.management_subnet_name,
        "subnets": [
          {
            "iaas_identifier": "$OPS_MANAGER_IAAS_IDENTIFIER",
            "cidr": .paver_paving_output.infrastructure_subnet_cidr.value,
            "reserved_ip_ranges": "10.0.8.0-10.0.8.5",
            "dns": "168.63.129.16",
            "gateway": .paver_paving_output.infrastructure_subnet_gateway.value
          }
        ]
      },
      {
        "name": .paver_iaas_specific_output.services_subnet_name,
        "service_network": true,
        "subnets": [
          {
            "iaas_identifier": "$SERVICES_IAAS_IDENTIFIER",
            "cidr": .paver_paving_output.services_subnet_cidr.value,
            "reserved_ip_ranges": "10.0.4.0-10.0.4.3",
            "dns": "168.63.129.16",
            "gateway": .paver_paving_output.services_subnet_gateway.value
          }
        ]
      }
    ]
  },
  "network-assignment": {
    "singleton_availability_zone": {
      "name":"zone-1"
    },
    "network": {
      "name":"$OPSMAN_NETWORK_NAME"
    }
  },
  "properties-configuration": {
    "security_configuration": {
      "include_opsmanager_root_ca_in_trusted_certificates": true,
    },
    "iaas_configuration": {
      "subscription_id": "$SUBSCRIPTION_ID",
      "tenant_id": "$TENANT_ID",
      "client_id": "$CLIENT_ID",
      "client_secret": "$CLIENT_SECRET",
      "resource_group_name": .paver_iaas_specific_output.pcf_resource_group_name,
      "bosh_storage_account_name": .paver_iaas_specific_output.bosh_root_storage_account,
      "default_security_group": .paver_iaas_specific_output.ops_manager_security_group_name,
      "ssh_public_key": "$PUBLIC_KEY",
      "ssh_private_key": "$PRIVATE_KEY",
      "deployments_storage_account_name": .paver_iaas_specific_output.cf_storage_account_name,
      "identification_tags_string": "env-name:$ENV_NAME"
    },
    "director_configuration": {
      "ntp_servers_string": "us.pool.ntp.org",
      "post_deploy_enabled": true,
      "keep_unreachable_vms": false
    },
    "resource_configuration": {
      "compilation": {
        "internet_connected": true,
        "instance_type": {
            "id": "Standard_F8s"
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
}
EOF
fi

iaas_configuration=$(jq -r ". | $iaas_jq_input" $ENV_FILE)

echo $iaas_configuration
exit 0
