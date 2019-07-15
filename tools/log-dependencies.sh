#!/usr/bin/env bash

set -ueo pipefail

base_image_log_dependencies="${HOME}/base-image-dependencies.log"

if [[ -f "${base_image_log_dependencies}" ]]; then
    cat "${base_image_log_dependencies}"
else
    exit 1
fi