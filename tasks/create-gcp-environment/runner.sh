#!/bin/bash

set -e

# needs check
./gips_client.sh "${OPS_MAN_VERSION}" "/input/${CRED_FILE}" "${GIPS_ADDRESS}" "${GIPS_UAA_ADDRESS}"
