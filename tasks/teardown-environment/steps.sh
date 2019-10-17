#!/bin/bash

function needs_check {
    mrlog section-start --name="checking task needs"

    needs check
    result=$?
    mrlog section-end --name="checking task needs" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "Needs check indicated that the task is not ready to execute" >&2
    fi
    return $result
}

function create_environment {
    mrlog section-start --name="teardown environment"

    ./teardown.sh "${INSTALLATION_NAME}" "/input/${CRED_FILE}" "${GIPS_ADDRESS}" "${GIPS_UAA_ADDRESS}"
    result=$?
    mrlog section-end --name="teardown environment" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "environment teardown failed" >&2
    fi
    return $result
}
