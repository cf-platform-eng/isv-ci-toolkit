#!/bin/bash
set -eo pipefail

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
if [[ ! -f "$CRED_FILE" ]]; then
  echo "\"$CRED_FILE\" was not found"
	exit 1
fi
if ! jq -r . "$CRED_FILE" > /dev/null 2>&1 ; then
  echo "\"$CRED_FILE\" is not valid JSON"
  exit 1
fi

if [[ -z "$GIPS_ADDRESS" ]]; then
	GIPS_ADDRESS="podium.tls.cfapps.io"
fi

if ! CLIENT_ID=$(jq -er ".client_id" "$CRED_FILE") ; then
  echo 'credential file missing "client_id"'
  exit 1
fi

if ! CLIENT_SECRET=$(jq -er ".client_secret" "$CRED_FILE") ; then
  echo 'credential file missing "client_secret"'
  exit 1
fi

if ! SERVICE_ACCOUNT_KEY=$(jq -er ".service_account_key" "$CRED_FILE") ; then
  echo 'credential file missing "service_account_key"'
  exit 1
fi

if ! uaac target "$GIPS_UAA_ADDRESS" ; then
  echo 'failed to set UAA target'
  exit 1
fi

if ! uaac token client get "$CLIENT_ID" -s "$CLIENT_SECRET" ; then
  echo 'failed to get UAA client token'
  exit 1
fi

if ! ACCESS_TOKEN=$(uaac context "$CLIENT_ID" | grep access_token | xargs | cut -d" " -f2) ; then
  echo 'failed to get UAA access token'
  exit 1
fi

set +e
read -r -d '' GIPS_INSTALL_REQUEST <<INSTALL
{
  "iaas": "gcp",
  "paver_name": "prod_gcp",
  "opsman_version": "2.6.2",
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

if ! install_request=$(curl -H "Content-Type: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs" -d "${GIPS_INSTALL_REQUEST}") ; then
  echo "failed to submit installation request"
  exit 1
fi
install_name=$(echo "${install_request}" | jq -r ".name" )

while : ; do
  if ! installation=$(curl -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${install_name}/") ; then
    echo "failed to get installation status"
    exit 1
  fi
  install_status=$(echo "${installation}" | jq -r .paver_job_status)

  if [ "${install_status}" != "queued" ] && [ "${install_status}" != "working" ] ; then
    break
  fi

  sleep 60
done

if [ "${install_status}" = "failed" ] ; then
  echo 'installation failed:'
  echo "${installation}"
  exit 1
fi

mkdir -p output
echo "${installation}" > output/environment.json
