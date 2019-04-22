#!/usr/bin/env bash

export RELEASE_NAME="nsie-under-test"

function setup {
    pks login -a "${PKS_API_ENDPOINT}" -u "${PKS_USERNAME}" -p "${PKS_PASSWORD}" -k
}

function uninstall_chart {
    echo "Uninstalling ${RELEASE_NAME}..."
    helm delete --purge "${RELEASE_NAME}" --tiller-namespace kibosh || true
    kubectl delete namespace "${RELEASE_NAME}" || true
}

function cleanup_helm {
    helm reset --force --tiller-namespace kibosh

    # this is because bazaar uses older helm (afaik)
    # this issue: https://github.com/helm/helm/issues/4825
    # fix in helm: https://github.com/helm/helm/pull/5161 (2.13.0)
    # pending this fix in bazaar: https://www.pivotaltracker.com/story/show/164841753
    kubectl delete rs/tiller-deploy-7b5577cfd7 -n kibosh
}

function cleanup {
    uninstall_chart
    cleanup_helm
}

function install_chart {
    echo "Installing ${RELEASE_NAME} with bazaar..."

    bazaar chart install --verbose --cluster-name "${CLUSTER_NAME}" --name "${RELEASE_NAME}" --source-directory "${CHART_DIRECTORY}"
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

function test_chart {
    echo "Testing ${RELEASE_NAME}..."
    helm test "${RELEASE_NAME}" --debug --cleanup --tiller-namespace kibosh
}

function run {
    setup
    install_chart
    test_chart
}
