#!/usr/bin/env bash

export RELEASE_NAME="nsie-under-test"

echo "exporting: setup"
function setup {
    echo "fn:setup"
    pks login -a "${PKS_API_ENDPOINT}" -u "${PKS_USERNAME}" -p "${PKS_PASSWORD}" -k
}

function uninstall_chart {
    echo "fn:uninstall_chart"
    helm delete --purge "${RELEASE_NAME}" --tiller-namespace kibosh || true
    kubectl delete namespace "${RELEASE_NAME}" || true
}

function cleanup_helm {
    echo "fn:cleanup_helm"
    helm reset --force --tiller-namespace kibosh

    # this is because bazaar uses older helm (afaik)
    # this issue: https://github.com/helm/helm/issues/4825
    # fix in helm: https://github.com/helm/helm/pull/5161
    # pending this fix in bazaar: https://www.pivotaltracker.com/story/show/164841753
    kubectl delete rs/tiller-deploy-88458558f -n kibosh
}

echo "exporting: cleanup"
function cleanup {
    uninstall_chart
    cleanup_helm
}

echo "exporting: download_chart"
function download_chart {
    mkdir -p /input/chart
    bazaar chart pivnet-list -a "${PIVNET_TOKEN}"
    bazaar chart download -a "${PIVNET_TOKEN}" -r 0.0.1 -d /input/chart -p z-pe-test-helm-release
}

echo "exporting: install_chart"
function install_chart {
    echo "fn:install_chart"
    echo "Installing ${RELEASE_NAME} with bazaar..."

    bazaar chart install --verbose --cluster-name "${CLUSTER_NAME}" --name "${RELEASE_NAME}" --source-directory /input/chart
    helm --tiller-namespace kibosh list

    # This wait logic copied from https://github.com/cf-platform-eng/bazaar/blob/master/ci/pipeline.yml#L937-L948
    sleep 2
    while kubectl get pods --all-namespaces | grep -E "(Pending|Init)" > /dev/null; do
        sleep 2
        echo "Found Pending pods. Taking a nap"
    done

    # Added filter for "Completed" to avoid getting hung up on job pods
    while kubectl get pods --namespace ${RELEASE_NAME} | grep -v "Completed" | grep "0/1" > /dev/null; do
        sleep 2
        echo "Found pods not running yet. Taking a nap"
    done

    helm --tiller-namespace kibosh list

    trap cleanup EXIT
}

echo "exporting: test_chart"
function test_chart {
    echo "fn:test_chart"
    echo "Running test..."

    MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace "${RELEASE_NAME}" "${RELEASE_NAME}-mysql" -o jsonpath="{.data.mysql-root-password}" | base64 --decode)
    kubectl port-forward "svc/${RELEASE_NAME}-mysql" 3306:3306 --namespace "${RELEASE_NAME}" &

    sleep 10

    mysql -h 127.0.0.1 -P3306 -u root -p"${MYSQL_ROOT_PASSWORD}" -e "select * from mysql.db;"
}

echo "exporting: run"
function run {
    setup
    download_chart
    install_chart
    test_chart
}
