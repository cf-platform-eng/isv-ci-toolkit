#!/usr/bin/env bash

if [[ -z "${GCP_CREDS_FILE}" ]] ; then
    >&2 echo "GCP_CREDS_FILE must be defined"
    exit 1
fi

usage() {
    echo "Usage: "
    echo -e "\tcreate-cluster.sh <cluster-name> <gcs zone>"
    echo -e "\t\t<cluster-name> name of cluster to create"
    echo -e "\t\t<gcs zone> gcs zone to create cluster in, defaults to us-central1"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

CERT_DIR=$(dirname "${GCP_CREDS_FILE}")
CERT_FILE=$(basename "${GCP_CREDS_FILE}")
PROJECT=$(cat ${GCP_CREDS_FILE} | jq -r '.project_id')

DOCKER_OPTS="-e CLOUDSDK_CONFIG=/config/mygcloud -v `pwd`/mygcloud:/config/mygcloud -v ${CERT_DIR}:/tmp/certs -v `pwd`/pci:/pci google/cloud-sdk:latest"

# if no credentials, create default auth config and authenticate
if [ ! -f mygcloud/configurations/config_default ]; then
    mkdir -p mygcloud/configurations

    echo [auth] > mygcloud/configurations/config_default
    echo credential_file_override = /tmp/certs/${CERT_FILE} >> mygcloud/configurations/config_default

    # authenticate and set default project
    docker run -it $DOCKER_OPTS \
      gcloud auth activate-service-account --key-file=/tmp/certs/svc_account.json 
    docker run -it $DOCKER_OPTS \
      gcloud config set project ${PROJECT}
fi

ZONE=us-central1

if [ $# -gt 1 ]; then
    ZONE=$2
fi

# create cluster
docker run -it $DOCKER_OPTS \
  /bin/bash -c "gcloud container clusters create $1 --zone ${ZONE} &&kubectl config current-context && kubectl config rename-context gke_${PROJECT}_${ZONE}_$1 $1 && cp /root/.kube/config /pci/k8s/config"

