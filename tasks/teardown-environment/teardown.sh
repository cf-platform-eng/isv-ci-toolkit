#!/bin/bash
set -eo pipefail

INSTALLATION_NAME="$1"
CRED_FILE="$2"
GIPS_ADDRESS="$3"
GIPS_UAA_ADDRESS="$4"
default_gips_address="podium.tls.cfapps.io"
default_gips_uaa_address="gips-prod.login.run.pivotal.io"

function usage {
  echo "USAGE: teardown <name> <credential file> [<GIPS address>] [<GIPS UAA address>]"
  echo "    name - name of the installation as known by podium/GIPS"
  echo "    credential file - JSON file containing credentials.  Must include:"
  echo "        client_id"
  echo "        client_secret"
  echo "    GIPS address - target podium instance (default: ${default_gips_address})"
  echo "    GIPS UAA address - override the authentication endpoint for GIPS (default: ${default_gips_uaa_address})"
}

if [[ -z "${INSTALLATION_NAME}" ]]; then
	echo "no installation name provided"
  usage
	exit 1
fi
if [[ -z "$CRED_FILE" ]]; then
	echo "no credential file provided"
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
  echo 'credential file missing "client_id"'
  usage
  exit 1
fi

CLIENT_SECRET=$(jq -r ".client_secret // empty" "$CRED_FILE")
if [[ -z "${CLIENT_SECRET}" ]] ; then
  echo 'credential file missing "client_secret"'
  usage
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


if ! curl -X DELETE -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${INSTALLATION_NAME}" ; then
  echo "failed to submit deletion request"
  exit 1
fi

while : ; do
  if ! installation=$(curl -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${INSTALLATION_NAME}") ; then
    if [ "$(echo "$installation" | grep -c "404 Not Found")" -eq 1 ]; then
      break
    fi

    echo "failed to get deletion status"
    exit 1
  fi

  teardown_status=$(echo "${installation}" | jq -r .paver_job_status)
  if [ "${teardown_status}" != "queued" ] && [ "${teardown_status}" != "deleting" ] && [ "${teardown_status}" != "complete" ]; then
    break
  fi

  sleep 60
done

if [ "${teardown_status}" = "failed" ] ; then
  echo 'deletion failed:'
  echo "${installation}"
  exit 1
fi

echo "deletion of ${INSTALLATION_NAME} succeeded"
