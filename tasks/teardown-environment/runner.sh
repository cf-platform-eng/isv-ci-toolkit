#!/bin/bash

set -e

# needs check
./teardown.sh "${INSTALLATION_NAME}" "/input/${CRED_FILE}" "${GIPS_ADDRESS}" "${GIPS_UAA_ADDRESS}"
