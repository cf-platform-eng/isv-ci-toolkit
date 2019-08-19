#!/bin/bash

mrlog section-start --name="needs check"
needs check
result=$?
mrlog section-end --name="needs check" --result=${result}
if [[ $result -ne 0 ]] ; then
    echo "needs check failed" >&2
    exit 1
fi

mrlog section-start --name="create environment"
./gips_client.sh "${OPS_MAN_VERSION}" "/input/${CRED_FILE}" "${GIPS_ADDRESS}" "${GIPS_UAA_ADDRESS}"
mrlog section-end --name="create environment" --result=$?
