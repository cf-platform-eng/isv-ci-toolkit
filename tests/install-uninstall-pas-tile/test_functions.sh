#!/usr/bin/env bash

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

function config_file_check {
    mrlog section-start --name="config file check"
    tileinspect check-config --tile "/input/tile/${TILE_NAME}" --config "/input/tile-config/${TILE_CONFIG}"
    result=$?
    mrlog section-end --name="config file check" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "The supplied config file will not work for the tile" >&2
    fi
    return $result
}

function log_dependencies {
    mrlog section-start --name="dependencies"
    if [ -f /root/dependencies.log ] ; then
        cat /root/dependencies.log
    fi
    mrlog section-end --name="dependencies" --result=0
}

function install_tile {
    mrlog section-start --name="tile install"
    install-tile.sh "/input/tile/${TILE_NAME}" "/input/tile-config/${TILE_CONFIG}" "${USE_FULL_DEPLOY:-false}"
    result=$?
    mrlog section-end --name="tile install" --result=$result
    if [[ $result -ne 0 ]] ; then
        echo "Failed to stage, configure, or deploy the tile" >&2
    fi
    return $result
}

function uninstall_tile {
    mrlog section-start --name="tile uninstall"
    uninstall-tile.sh "/input/tile/${TILE_NAME}" "${USE_FULL_DEPLOY:-false}"
    result=$?
    mrlog section-end --name="tile uninstall" --result=$result
    if [[ $result -ne 0 ]] ; then
        echo "Failed to uninstall the tile" >&2
    fi
    return $result
}
