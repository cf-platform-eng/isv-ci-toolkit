#!/bin/bash
set -eo pipefail

OPS_MAN_VERSION="$1"
CRED_FILE="$2"
GIPS_ADDRESS="$3"
GIPS_UAA_ADDRESS="$4"
default_gips_address="podium.tls.cfapps.io"
default_gips_uaa_address="gips-prod.login.run.pivotal.io"

function usage {
  echo "USAGE: gips_client <OpsManager version> <credential file> [<GIPS address>] [<GIPS UAA address>]"
  echo "    OpsManager version - the vesion of the OpsManager that should be created"
  echo "    credential file - JSON file containing credentials.  Must include:"
  echo "        client_id"
  echo "        client_secret"
  echo "        service_account_key"
  echo "    GIPS address - target podium instance (default: ${default_gips_address})"
  echo "    GIPS UAA address - override the authentication endpoint for GIPS (default: ${default_gips_uaa_address})"
}

if [[ -z "${OPS_MAN_VERSION}" ]]; then
	echo "No OpsManager version provided"
  usage
	exit 1
fi
if [[ -z "$CRED_FILE" ]]; then
	echo "No credential file provided"
  usage
	exit 1
fi
if [[ ! -f "$CRED_FILE" ]]; then
  echo "\"$CRED_FILE\" was not found"
  usage
	exit 1
fi
if ! jq -r . "$CRED_FILE" > /dev/null 2>&1 ; then
  echo "\"$CRED_FILE\" is not valid JSON"
  usage
  exit 1
fi

if [[ -z "$GIPS_ADDRESS" ]]; then
	GIPS_ADDRESS="${default_gips_address}"
fi
if [[ -z "$GIPS_UAA_ADDRESS" ]]; then
  GIPS_UAA_ADDRESS="${default_gips_uaa_address}"
fi

CLIENT_ID=$(jq -r ".client_id // empty" "$CRED_FILE")
if [[ -z "${CLIENT_ID}" ]] ; then
  echo 'Credential file missing "client_id"'
  usage
  exit 1
fi

CLIENT_SECRET=$(jq -r ".client_secret // empty" "$CRED_FILE")
if [[ -z "${CLIENT_SECRET}" ]] ; then
  echo 'Credential file missing "client_secret"'
  usage
  exit 1
fi

SERVICE_ACCOUNT_KEY=$(jq -r ".service_account_key // empty" "$CRED_FILE")
if [[ -z "${SERVICE_ACCOUNT_KEY}" ]] ; then
  echo 'Credential file missing "service_account_key"'
  usage
  exit 1
fi

echo "Authenticating with GIPS..."
if ! uaac target "$GIPS_UAA_ADDRESS" > /dev/null ; then
  echo 'Failed to set UAA target'
  exit 1
fi

if ! uaac token client get "$CLIENT_ID" -s "$CLIENT_SECRET" > /dev/null ; then
  echo 'Failed to get UAA client token'
  exit 1
fi

if ! ACCESS_TOKEN=$(uaac context "$CLIENT_ID" | grep access_token | xargs | cut -d" " -f2) ; then
  echo 'Failed to get UAA access token'
  exit 1
fi

set +e
read -r -d '' GIPS_INSTALL_REQUEST <<INSTALL
{
  "iaas": "gcp",
  "paver_name": "prod_gcp",
  "opsman_version": "${OPS_MAN_VERSION}",
  "dns_suffix": "cfplatformeng.com",
  "credentials": {
    "service_account_key": $SERVICE_ACCOUNT_KEY
  },
  "options": {
    "dns_service": {
      "zone_name": "cfplatformeng",
      "service_account_key": $SERVICE_ACCOUNT_KEY
    },
    "region": "us-central1",
    "zones": [
      "us-central1-a",
      "us-central1-b",
      "us-central1-c"
    ],
    "buckets_location": "US",
    "create_blobstore_service_account_key": true,
    "create_iam_service_account_members": true
  }
}
INSTALL
set -e

echo "Submitting environment request..."
if ! install_request=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs" -d "${GIPS_INSTALL_REQUEST}") ; then
  echo "Failed to submit installation request"
  exit 1
fi
install_name=$(echo "${install_request}" | jq -r ".name" )
echo -n "Environment is being created \"${install_name}\""

while : ; do
  if ! installation=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${install_name}/") ; then
    echo
    echo "Failed to get installation status"
    exit 1
  fi
  install_status=$(echo "${installation}" | jq -r .paver_job_status)

  if [ "${install_status}" != "queued" ] && [ "${install_status}" != "working" ] ; then
    break
  fi
  echo -n "."

  sleep 60
done

echo
if [ "${install_status}" = "failed" ] ; then
  echo 'Environment creation failed:'
  echo "${installation}"
  exit 1
fi

echo "Environment created!"
echo "${installation}" > /output/environment.json
