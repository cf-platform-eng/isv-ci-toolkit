#!/usr/bin/env bash

usage() {
    echo "Usage: "
    echo -e "\tcreate-cluster.sh <cluster name> <cluster plan> -n <worker node count>"
    echo -e "\t\t<cluster name> name of cluster to create"
    echo -e "\t\t<cluster plan> plan to apply to cluster (default is 'small')"
    echo -e "\t\t-n <worker node count> number of worker nodes to create (defaults to plan default)"
}
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

me="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

"${me}"/cluster.sh create "$@"

docker run -it \
  -v "$(pwd)/pci:/pci" \
  gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
  /bin/bash -c "pks login -a ${PKS_API} -u ${PKS_USER_NAME} -k -p ${PKS_PASSWORD} && KUBECONFIG=/pci/k8s/config pks get-credentials $1"