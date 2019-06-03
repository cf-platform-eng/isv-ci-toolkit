#!/usr/bin/env bash

tileinspect metadata --tile "${TILE_PATH}" > /tmp/metadata.yml
ops-manifest --metadata-path /tmp/metadata.yml --config-file "${CONFIG_FILE_PATH}"