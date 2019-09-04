#!/usr/bin/env bash

mrlog section-start --name="needs check"
needs check
result=$?
mrlog section-end --name="needs check" --result=${result}
if [[ $result -ne 0 ]] ; then
    echo "needs check failed" >&2
    exit 1
fi

mrlog section-start --name="config file check"
tileinspect check-config --tile "/input/tile/${TILE_NAME}" --config "/input/tile-config/${TILE_CONFIG}"
result=$?
mrlog section-end --name="config file check" --result=${result}
if [[ $result -ne 0 ]] ; then
    echo "config file check failed" >&2
    exit 1
fi

mrlog section-start --name="dependencies"
if [ -f /root/dependencies.log ] ; then
    cat /root/dependencies.log
fi
mrlog section-end --name="dependencies" --result=0

mrlog section-start --name="tile install"
install-tile.sh "/input/tile/${TILE_NAME}" "/input/tile-config/${TILE_CONFIG}" "${USE_FULL_DEPLOY:-false}"
result=$?
mrlog section-end --name="tile install" --result=$result
if [[ $result -ne 0 ]] ; then
    echo "install-tile failed" >&2
    exit 1
fi

mrlog section-start --name="tile uninstall"
uninstall-tile.sh "/input/tile/${TILE_NAME}" "${USE_FULL_DEPLOY:-false}"
result=$?
mrlog section-end --name="tile uninstall" --result=$result
if [[ $result -ne 0 ]] ; then
    echo "uninstall-tile failed" >&2
    exit 1
fi
