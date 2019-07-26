#!/bin/bash
set -e

GIPS_UAA_ADDRESS="$1"
CRED_FILE="$2"
GIPS_ADDRESS="$3"

if [[ -z "$GIPS_UAA_ADDRESS" ]]; then
	echo "no gips uaa address provided"
	exit 1
fi

if [[ -z "$CRED_FILE" ]]; then
	echo "no credential file provided"
	exit 1
fi

if [[ -z "$GIPS_ADDRESS" ]]; then
	GIPS_ADDRESS="podium.tls.cfapps.io"
fi

CLIENT_ID=$(jq -r ".client_id" "$CRED_FILE")
CLIENT_SECRET=$(jq -r ".client_secret" "$CRED_FILE")
SERVICE_ACCOUNT_KEY=$(jq -r ".service_account_key" "$CRED_FILE")

uaac target "$GIPS_UAA_ADDRESS" 
uaac token client get "$CLIENT_ID" -s "$CLIENT_SECRET"

ACCESS_TOKEN=$(uaac context "$CLIENT_ID" | grep access_token | xargs | cut -d" " -f2)

set +e
read -r -d '' GIPS_INSTALL_REQUEST <<INSTALL
{
  "iaas": "gcp",
  "paver_name": "prod_gcp",
  "opsman_version": "2.6.2",
  "dns_suffix": "cfplatformeng.com",
  "credentials": {
    "service_account_key": "$SERVICE_ACCOUNT_KEY"
  },
  "options": {
    "dns_service": {
      "zone_name": "aws-or-gcp-or-azure",
      "service_account_key": {}
    },
    "region": "us-central1",
    "zones": [
      "us-central-1a",
      "us-central-1b",
      "us-central-1c"
    ],
    "buckets_location": "US",
    "create_blobstore_service_account_key": true,
    "create_iam_service_account_members": true,
  }
}
INSTALL
set -e

install_request=$(curl -X POST -H "Authorization: $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs" -d "$GIPS_INSTALL_REQUEST")

install_name=$(echo "${install_request}" | jq -r ".name" )

installation=$(curl -H "Authorization: $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${install_name}/")
install_status=$(echo "${installation}" | jq -r .paver_job_status)
while [ "${install_status}" = "queued" ] || [ "${install_status}" = "working" ]
do
  sleep 60
  installation=$(curl -H "Authorization: $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${install_name}/")
  install_status=$(echo "${installation}" | jq -r .paver_job_status)
done

echo "${installation}" > environment.json
