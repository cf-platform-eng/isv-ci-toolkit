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
	echo "No installation name provided"
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

echo "Authenticating with GIPS..."
if ! uaac target "$GIPS_UAA_ADDRESS" > /dev/null ; then
  echo 'Failed to set UAA target'
  exit 1
fi

if ! uaac token client get "$CLIENT_ID" > /dev/null -s "$CLIENT_SECRET" ; then
  echo 'Failed to get UAA client token'
  exit 1
fi

if ! ACCESS_TOKEN=$(uaac context "$CLIENT_ID" | grep access_token | xargs | cut -d" " -f2) ; then
  echo 'Failed to get UAA access token'
  exit 1
fi

echo "Submitting environment deletion request..."
if ! curl -s -X DELETE -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${INSTALLATION_NAME}" ; then
  echo "Failed to submit deletion request"
  exit 1
fi
echo -n "Environment is being deleted \"${INSTALLATION_NAME}\""

while : ; do
  if ! installation=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "https://$GIPS_ADDRESS/v1/installs/${INSTALLATION_NAME}") ; then
    if [ "$(echo "$installation" | grep -c "404 Not Found")" -eq 1 ]; then
      break
    fi
    echo
    echo "Failed to get deletion status"
    exit 1
  fi

  teardown_status=$(echo "${installation}" | jq -r .paver_job_status)
  if [ "${teardown_status}" != "queued" ] && [ "${teardown_status}" != "deleting" ] && [ "${teardown_status}" != "complete" ]; then
    break
  fi
  echo -n "."

  sleep 60
done

echo
if [ "${teardown_status}" = "failed" ] ; then
  echo 'Environment deletion failed:'
  echo "${installation}"
  exit 1
fi

echo "Environment deleted!"

