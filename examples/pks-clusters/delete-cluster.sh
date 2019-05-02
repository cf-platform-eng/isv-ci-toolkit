#!/usr/bin/env bash

usage() {
    echo "Usage: "
    echo -e "delete-cluster.sh <cluster name>"
}
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

me="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

${me}/cluster.sh delete $@
