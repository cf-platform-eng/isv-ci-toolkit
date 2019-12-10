#!/usr/bin/env bash

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && \
  echo -e "You must source this script\nsource ${0}" && \
  exit 1


function needs_check {
    mrlog section-start --name="checking test needs"

    needs check
    result=$?
    mrlog section-end --name="checking test needs" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "Needs check indicated that the test is not ready to execute" >&2
    fi
    return $result
}

function requirements_check {
  mrlog section-start --name "requirements check"

  needs check
  result=$?

  if [[ $result -eq 0 ]] ; then
    echo "The requirements in needs.json were met"
  else
    echo "The requirements in needs.json were not completely met"
  fi

  mrlog section-end --name "requirements check" --result=1

  return $result
}

function log_dependencies {
    mrlog section-start --name="dependencies"
    if [ -f /root/dependencies.log ] ; then
        cat /root/dependencies.log
    fi
    mrlog section-end --name="dependencies" --result=0
}

function config_file_check {
    mrlog section-start --name="config file check"
    tileinspect check-config --tile "${TILE_PATH}" --config "${TILE_CONFIG_PATH}"
    result=$?
    mrlog section-end --name="config file check" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "The supplied config file will not work for the tile" >&2
    fi
    return $result
}

function log_existing_dependencies {
  mrlog section-start --name "log existing dependencies"

  cat "${DEPENDENCIES_FILE}"
  result=$?

  mrlog section-end --name "log existing dependencies" --result=0
  return $result
}

function generate_service_account {
  mrlog section-start --name="generate service account"

  kubectl apply -f SERVICE-ACCOUNT.yml
  result=$?

  mrlog section-end --name="generate service account" --result=$result
}

function generate_config_file {
  mrlog section-start --name="generate tile config"

  result=$?

  secret_name=$(kubectl get serviceaccount ksm-admin --namespace=kube-system -o jsonpath='{.secrets[0].name}')
  secret_val=$(kubectl --namespace=kube-system get secret "$secret_name" -o jsonpath='{.data.token}')

  KSM_CLUSTER_TOKEN=$(echo "${secret_val}" | base64 --decode)


  mrlog section-end --name="generate tile config" --result=$result
}

function install_tile {
  mrlog section-start --name="tile install"
  install-tile.sh "${TILE_PATH}" "${TILE_CONFIG_PATH}" "${USE_FULL_DEPLOY:-false}"
  result=$?
  mrlog section-end --name="tile install" --result=$result
  if [[ $result -ne 0 ]] ; then
    echo "Failed to stage, configure, or deploy the tile" >&2
  fi
  return $result
}

function uninstall_tile {
  mrlog section-start --name="tile uninstall"
  uninstall-tile.sh "${TILE_PATH}" "${USE_FULL_DEPLOY:-false}"
  result=$?
  mrlog section-end --name="tile uninstall" --result=$result
  if [[ $result -ne 0 ]] ; then
    echo "Failed to uninstall the tile" >&2
  fi
  return $result
}
