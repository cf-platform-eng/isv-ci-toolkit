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
  marman github-download-release -o genevieve -r leftovers -f .*linux-amd64
  mv leftovers*linux-amd64 /usr/local/bin/leftovers
  chmod +x /usr/local/bin/leftovers
  mrlog dependency --name="leftovers" --version="$(leftovers -v 2>&1)"
}

function config_file_check() {
  mrlog section-start --name="config file check"

  tileinspect check-config --tile /tmp/ksm-*.pivotal --config "/tmp/ksm-config.yml"

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

function run_leftovers() {
  # shellcheck disable=SC2002
  mrlog section --name="remove all gcp resources" -- \
    "$PWD/lib/teardown" <(echo "${STORAGE_SERVICE_ACCOUNT_KEY}") "ksm-$(cat /input/pas-environment.json | jq -r .name)"
}

function teardown() {
  mrlog section-start --name="teardown"

    install_leftovers
    result=$?

    if [[ $result -eq 0 ]]; then
      run_leftovers
      result=$?
    fi

  mrlog section-end --name="teardown" --result=${result}
  return $result
}

function prepare_chart_storage() {
      # KSM prefix avoids collision with leftovers and the original PAS if they're hosted within the same project
      # shellcheck disable=SC2002
      mrlog section --name="prepare chart storage" -- \
        "$PWD/lib/prepare_chart_storage" \
        "${STORAGE_SERVICE_ACCOUNT_KEY}" \
        /input/pas-environment.json
}

function install_pks_cli() {
  mrlog section --name="Get PKS CLI" -- \
    "$PWD/lib/install_pks_cli"
}

function get_pks_credentials() {
  mrlog section --name="Get PKS credentials" -- \
    "$PWD/lib/get_pks_credentials"
}

function download_ksm_tile() {
  mrlog section-start --name="download ksm tile"

  (
    mkdir -p "/tmp/" &&
      cd "/tmp/" &&
      marman tanzu-network-download -s container-services-manager -f ksm-.*\.pivotal
  )

  result=$?
  if [[ $result -ne 0 ]]; then
    echo "Failed to stage, configure, or deploy the tile" >&2
  fi
  mrlog section-end --name="download ksm tile" --result=$result
  return $result
}

function generate_ksm_tile_config() {
  mrlog section --name="generate ksm tile config" -- \
    "$PWD/lib/generate_ksm_tile_config"
}

function install_tile() {
  mrlog section-start --name="tile install"

  # shellcheck disable=SC2002 disable=SC2155
  export OM_TARGET="$(cat /input/pas-environment.json | jq -r .ops_manager.url)"
  # shellcheck disable=SC2002 disable=SC2155
  export OM_USERNAME="$(cat /input/pas-environment.json | jq -r .ops_manager.username)"
  # shellcheck disable=SC2002 disable=SC2155
  export OM_PASSWORD="$(cat /input/pas-environment.json | jq -r .ops_manager.password)"
  export OM_SKIP_SSL_VALIDATION=true

  install-tile.sh /tmp/ksm-*.pivotal "/tmp/ksm-config.yml" "${USE_FULL_DEPLOY:-false}"
  result=$?
  if [[ $result -ne 0 ]]; then
    echo "Failed to stage, configure, or deploy the tile" >&2
  fi
  mrlog section-end --name="tile install" --result=$result
  return $result
}

function uninstall_tile() {
  mrlog section-start --name="tile uninstall"
  uninstall-tile.sh /tmp/ksm-*.pivotal "${USE_FULL_DEPLOY:-false}"
  result=$?
  mrlog section-end --name="tile uninstall" --result=$result
  if [[ $result -ne 0 ]]; then
    echo "Failed to uninstall the tile" >&2
  fi
  return $result
}
