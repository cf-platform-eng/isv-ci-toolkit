#!/usr/bin/env bash

[[ "${BASH_SOURCE[0]}" == "${0}" ]] &&
  echo -e "You must source this script\nsource ${0}" &&
  exit 1

function needs_check() {
  mrlog section-start --name="checking test needs"

  needs check
  result=$?
  mrlog section-end --name="checking test needs" --result=${result}

  if [[ $result -ne 0 ]]; then
    echo "Needs check indicated that the test is not ready to execute" >&2
  fi
  return $result
}

function requirements_check() {
  mrlog section-start --name "requirements check"

  needs check
  result=$?

  if [[ $result -eq 0 ]]; then
    echo "The requirements in needs.json were met"
  else
    echo "The requirements in needs.json were not completely met"
  fi

  mrlog section-end --name "requirements check" --result=1

  return $result
}

function log_dependencies() {
  mrlog section-start --name="dependencies"
  if [ -f /root/dependencies.log ]; then
    cat /root/dependencies.log
  fi
  mrlog section-end --name="dependencies" --result=0
}

function install_leftovers() {
  marman download-release -o genevieve -r leftovers -f .*linux-amd64
  mv leftovers*linux-amd64 /usr/local/bin/leftovers
  chmod +x /usr/local/bin/leftovers
  mrlog dependency --name="leftovers" --version="$(leftovers -v 2>&1)"
}

function config_file_check() {
  mrlog section-start --name="config file check"
  tileinspect check-config --tile "${TILE_PATH}" --config "${TILE_CONFIG_PATH}"
  result=$?
  mrlog section-end --name="config file check" --result=${result}

  if [[ $result -ne 0 ]]; then
    echo "The supplied config file will not work for the tile" >&2
  fi
  return $result
}

function log_existing_dependencies() {
  mrlog section-start --name "log existing dependencies"

  cat "${DEPENDENCIES_FILE}"
  result=$?

  mrlog section-end --name "log existing dependencies" --result=0
  return $result
}

function teardown() {
  mrlog section --name="remove all gcp resources" -- \
    ./lib/teardown /input/service_account_key.json "ksm-$(cat /input/env.json | jq -r .name)"

}

function prepare_chart_storage() {
  # KSM prefix avoids collision with leftovers and the original PAS if they're hosted within the same project
  mrlog section --name="prepare chart storage" -- \
    ./lib/prepare_chart_storage /input/service_account_key.json "ksm-$(cat /input/env.json | jq -r .name)"
}

function generate_service_account() {
  mrlog section-start --name="generate service account"

  kubectl apply -f SERVICE-ACCOUNT.yml
  result=$?

  mrlog section-end --name="generate service account" --result=$result
}

function generate_config_file() {
  mrlog section-start --name="generate tile config"

  result=$?

  ENVIRONMENT=$(cat /input/env.json)

  KUBECONFIG_ACTIVE=$(kubectl config current-context)
  if [[ -z "$KUBECONFIG_ACTIVE" ]]; then
    KSM_CLUSTER_CONFIG=$(kubectl config view --raw -o json | jq ".clusters[0]")
    kubectl config use-context $(echo "$KSM_CLUSTER_CONFIG" | jq .name)
  else
    export KSM_CLUSTER_CONFIG=$(kubectl config view --raw -o json | jq ".clusters[] | select(.name | contains(\"$KUBECONFIG_ACTIVE\"))")
  fi

  secret_name=$(kubectl get serviceaccount ksm-admin --namespace=kube-system -o jsonpath='{.secrets[0].name}')
  secret_val=$(kubectl --namespace=kube-system get secret "$secret_name" -o jsonpath='{.data.token}')

  export KSM_CLUSTER_CA=$(echo "$KSM_CLUSTER_CONFIG" | jq -r '.cluster."certificate-authority-data"')
  export KSM_CLUSTER_TOKEN=$(echo "${secret_val}" | base64 --decode)

  KSM_CLUSTER_ENDPOINT=$(echo "$KSM_CLUSTER_CONFIG" | jq -r '.cluster.server')
  KSM_CLUSTER_ENDPOINT=${KSM_CLUSTER_ENDPOINT#https://}
  port="$(echo $KSM_CLUSTER_ENDPOINT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
  export KSM_CLUSTER_ENDPOINT=$(echo "$KSM_CLUSTER_ENDPOINT" | sed 's/:.*//')
  if [[ -z "$port" ]]; then
    export KSM_CLUSTER_PORT=443
  else
    export KSM_CLUSTER_PORT=8443
  fi

  export AZ_1=$(echo "$ENVIRONMENT" | jq -r .azs[0])
  export SINGLETON_AZ=$(echo "$ENVIRONMENT" | jq -r .azs[0])
  export AZ_2=$(echo "$ENVIRONMENT" | jq -r .azs[1])
  export AZ_3=$(echo "$ENVIRONMENT" | jq -r .azs[2])

  export PAS_SUBNET=$(echo "$ENVIRONMENT" | jq -r .ert_subnet)

  cat ksm-config.template.yml | envsubst >ksm-config.yml

  mrlog section-end --name="generate tile config" --result=$result
}

function install_tile() {
  mrlog section-start --name="tile install"
  install-tile.sh "${TILE_PATH}" "${TILE_CONFIG_PATH}" "${USE_FULL_DEPLOY:-false}"
  result=$?
  mrlog section-end --name="tile install" --result=$result
  if [[ $result -ne 0 ]]; then
    echo "Failed to stage, configure, or deploy the tile" >&2
  fi
  return $result
}

function uninstall_tile() {
  mrlog section-start --name="tile uninstall"
  uninstall-tile.sh "${TILE_PATH}" "${USE_FULL_DEPLOY:-false}"
  result=$?
  mrlog section-end --name="tile uninstall" --result=$result
  if [[ $result -ne 0 ]]; then
    echo "Failed to uninstall the tile" >&2
  fi
  return $result
}
