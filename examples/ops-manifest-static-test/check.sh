#!/usr/bin/env bash

# TODO: This should be replaced with a standardized dependency check utility
if [[ -z "${TILE_PATH}" ]] ; then
    echo "TILE_PATH is not defined"
    exit 1
fi

if [[ -z "${CONFIG_FILE_PATH}" ]] ; then
    echo "CONFIG_FILE_PATH is not defined"
    exit 1
fi
