#!/usr/bin/env bash

set -ueo pipefail

install-tile.sh "/tile/${TILE_NAME}" "/tile-config/${TILE_CONFIG}"

uninstall-tile.sh "/tile/${TILE_NAME}"

