#!/usr/bin/env bash
echo "exporting: setup_k8s"
function setup_k8s {
    /test/configkube
#    echo -e "${KUBECONFIGFILE}" > /test/kubeconfig
#    export KUBECONFIG=/test/kubeconfig
}

function cleanup_helm {
    helm reset
    kubectl delete clusterrolebinding/tiller
}

echo "exporting: setup_helm"
function setup_helm {
    trap cleanup_helm EXIT

    kubectl apply -f rbac-config.yml
    helm init --wait --service-account tiller
}

echo "exporting: setup"
function setup {
    setup_k8s
    setup_helm
}

echo "exporting: get_mysql_chart"
function get_mysql_chart {
    git clone https://github.com/helm/charts
    #FIXME don't stay here
    cd charts/stable || exit
    helm package mysql
}

echo "exporting: clean"
function clean {
    helm ls --all | cut -f1 | grep -v "NAME" | xargs helm delete --purge || true
}

function uninstall_mysql {
    helm delete --purge mysql || true
}

echo "exporting: install_mysql"
function install_mysql {
    echo "Installing MySQL test..."
    get_mysql_chart
    helm install --wait mysql-*.tgz -n mysql
    echo "MySQL install status: $?"
    trap uninstall_mysql EXIT
}

echo "exporting: test_mysql"
function test_mysql {
    echo "Running MySQL test..."
    set -x
    helm test mysql --debug --cleanup
    set +x
}

echo "exporting: run"
function run {
    setup

    clean

    install_mysql
    test_mysql
}
