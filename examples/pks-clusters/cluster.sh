#!/usr/bin/env bash

if [[ -z "${PKS_API}" ]] ; then
    >&2 echo "PKS_API (url) must be defined"
    exit 1
fi

if [[ -z "${GCP_CREDS}" ]] ; then
    >&2 echo "GCP_CREDS must be defined"
    exit 1
fi

if [[ -z "${PKS_USER_NAME}" ]] ; then
    >&2 echo "PKS_USER_NAME. must be defined"
    exit 1
fi

if [[ -z "${PKS_PASSWORD}" ]] ; then
    >&2 echo "PKS_PASSWORD.. must be defined"
    exit 1
fi

usage() {
    echo "Usage: "
    echo -e "\tcluster.sh <operation> <options>"
    echo -e "\t\t<operation> pksctl cluster operation (create, delete, discover)"
    echo -e "\t\t<options> options valid for the given operation"
}

if [ $# -lt 2 ]; then
    usage
    exit 1
fi

docker run --rm  -it \
  -e PKS_API="${PKS_API}" \
  -e GCP_CREDS="${GCP_CREDS}" \
  -e PKS_USER_NAME="${PKS_USER_NAME}" \
  -e PKS_PASSWORD="${PKS_PASSWORD}" \
  cfplatformeng/toolkit-pas:latest \
  pksctl cluster $@