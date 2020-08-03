#!/usr/bin/env bash

function show_image_dependencies() {
  mrlog section --name="show image dependencies" -- cat /root/dependencies.log
}

function check_needs() {
  mrlog section --name="check needs" \
    --on-failure="Needs check indicated one or more needs were not satisfied" \
    --on-success="Needs check successfully found all the requirements for this test" \
    -- needs check
}

function download_tile() {
  if [ -f "${TILE_PATH}" ] ; then
    echo "The tile already exists"
    return 0
  fi

  if [ -z "${TILE_VERSION}" ] ; then
    mrlog section --name="download tile" \
    --on-failure="Failed to download ${TILE_SLUG}" \
    --on-success="Successfully downloaded ${TILE_SLUG}" \
    -- marman tanzu-network-download --slug "${TILE_SLUG}" --file ".pivotal$"
  else
    mrlog section --name="download tile" \
    --on-failure="Failed to download ${TILE_SLUG}" \
    --on-success="Successfully downloaded ${TILE_SLUG}" \
    -- marman tanzu-network-download --slug "${TILE_SLUG}" --version "${TILE_VERSION}" --file ".pivotal$"
  fi
}

function print_config_file() {
  mrlog section --name="print config file" \
    -- cat "${TILE_CONFIG_PATH}"
}

function check_config_file() {
  mrlog section --name="check config file" \
    --on-failure="config will not work with the tile" \
    --on-success="config is compatible with this tile" \
    -- tileinspect check-config --tile "${TILE_PATH}" --config "${TILE_CONFIG_PATH}"
}

function install_tile() {
  mrlog section --name="install tile" \
    --on-failure="failed to stage, configure, or deploy the tile" \
    --on-success="tile staged, configured and deployed successfully" \
    -- install-tile.sh "${TILE_PATH}" "${TILE_CONFIG_PATH}" "${USE_FULL_DEPLOY:-false}"
}
