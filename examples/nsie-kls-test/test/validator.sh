#!/usr/bin/env bash

RELEASE_NAME=$1

function finish {
    echo "Request to exit"
    exit 0
}

trap finish SIGHUP

function check {
    echo "Running health check"
    if ! helm test "${RELEASE_NAME}" --debug --cleanup --tiller-namespace kibosh ; then
        echo "Health check failed"
        exit 1
    fi
    echo "Health check passed"
}

echo "Starting validator"
while :
do
    check
    sleep 1
done