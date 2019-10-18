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
    mrlog section-start --name="creating environment"

    ./gips_client.sh "${OPS_MAN_VERSION}" "/input/credentials.json" "${OPTIONAL_OPS_MAN_VERSION}"
    result=$?
    mrlog section-end --name="creating environment" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "environment creation failed" >&2
    fi
    return $result
}
