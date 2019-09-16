#!/bin/bash

TEST_IMAGE=$1
if [[ -z "${TEST_IMAGE}" ]]; then
    echo "usage: run-test.sh <test image> [<additional parameters to docker>]"
    exit 1
fi
shift

EXTRA_ARGS=$@

dockerCmd="docker run -it"
needs=$(docker run -t ${TEST_IMAGE} needs list)
if [[ $? -ne 0 ]]; then
    echo "Failed to get the needs of this test"
    exit 1
fi

environmentVars=$(echo "${needs}" | jq -r '.[] | select(.type=="environment_variable") | .name')
for var in ${environmentVars}; do
    dockerCmd="${dockerCmd} -e ${var}"
done

echo "${dockerCmd} ${TEST_IMAGE} ${EXTRA_ARGS}"
${dockerCmd} ${TEST_IMAGE} ${EXTRA_ARGS}