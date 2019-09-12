#!/bin/bash

set -ueo pipefail

needs check

result=$(smith claim -p "${POOL_TYPE}")

export env
eval "${result}"
echo "Claimed environment ${env}"

smith read > "${TASK_OUTPUT:-/output}/environment.json"
