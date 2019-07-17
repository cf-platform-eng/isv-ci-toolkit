#!/usr/bin/env bash

mrlog section-start --name="needs check"
needs check
result=$?
mrlog section-start --name="needs check" --result=${result}
if [[ $result -ne 0 ]] ; then
    echo "needs check failed"
    exit 1
fi

log-dependencies.sh

mrlog section-start --name="tile install"
install-tile.sh "/tile/${TILE_NAME}" "/tile-config/${TILE_CONFIG}"
mrlog section-start --name="tile install" --result=$?

mrlog section-start --name="tile uninstall"
uninstall-tile.sh "/tile/${TILE_NAME}"
mrlog section-start --name="tile uninstall" --result=$?
