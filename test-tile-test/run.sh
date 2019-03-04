#!/usr/bin/env bash

usage() {
    echo "Usage: "
    echo -e "\n\trun <tile.pivotal> <target.json>"
    echo -e "\n"
    echo -e "\t   <tile.pivotal> path to tile .pivotal file"
    echo -e "\t   <target.json> poolsmiths provided target definition"
}

tile=${1:-""}
target_file=${2:-""}

if [[ -z "${tile}" ]]; then
    usage
    exit 1
fi

if [[ -z "${target_file}" ]]; then
    usage
    exit 1
fi

ops_mgr=$(cat ${target_file} | jq -r ".ops_manager")
echo $ops_mgr

docker run -it \
    -e OM_USERNAME=$(echo ${ops_mgr} | jq -r ".username") \
    -e OM_PASSWORD=$(echo ${ops_mgr} | jq -r ".password") \
    -e OM_TARGET=$(echo ${ops_mgr} | jq -r ".url") \
    -e OM_SKIP_SSL_VALIDATION=1 \
    cfplatformeng/test-tile-test:local
