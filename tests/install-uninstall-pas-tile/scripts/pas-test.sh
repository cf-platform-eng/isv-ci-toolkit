#!/usr/bin/env bash

mrlog section-start --name="needs check"
needs check
result=$?
mrlog section-end --name="needs check" --result=${result}
if [[ $result -ne 0 ]] ; then
    echo "needs check failed" >&2
    exit 1
fi

mrlog section-start --name="dependencies"
log-dependencies.sh
mrlog section-end --name="dependencies" --result=0

mrlog section-start --name="tile install"
install-tile.sh "/tile/${TILE_NAME}" "/tile-config/${TILE_CONFIG}" "${USE_FULL_DEPLOY:-false}"
result=$?
mrlog section-end --name="tile install" --result=$result
if [[ $result -ne 0 ]] ; then
    echo "install-tile failed" >&2
    exit 1
fi

mrlog section-start --name="tile uninstall"
uninstall-tile.sh "/tile/${TILE_NAME}" "${USE_FULL_DEPLOY:-false}"
result=$?
mrlog section-end --name="tile uninstall" --result=$result
if [[ $result -ne 0 ]] ; then
    echo "uninstall-tile failed" >&2
    exit 1
fi
