#!/usr/bin/env bash

TILE_METADATA=$(tileinspect metadata --tile "${TILE_PATH}")

ops-manifest --metadata-path <(echo "${TILE_METADATA}") --config-file "${CONFIG_FILE_PATH}"