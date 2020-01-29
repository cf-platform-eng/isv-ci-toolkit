#!/usr/bin/env bash

source ./steps.sh

log_dependencies          || exit 1
needs_check               || exit 1
prepare_chart_storage     || exit 1
download_ksm_tile         || exit 1
install_pks_cli           || exit 1
get_pks_credentials       || exit 1
generate_ksm_tile_config  || exit 1
config_file_check         || exit 1
install_tile              || exit 1

if [ "${TEARDOWN:-false}" == "true" ]; then
  teardown                || exit 1
fi
