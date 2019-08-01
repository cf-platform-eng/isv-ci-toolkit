#!/usr/bin/env bash
set -ueo pipefail

mrlog section-start --name="expected configuration"
if ! om staged-config --product-name "${1}" | yq -r . ; then
    echo "Failed to get staged config for ${1}" >&2
    echo "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true" >&2
    mrlog section-end --name="expected configuration" --result 1
    exit 1
fi
mrlog section-end --name="expected configuration"


mrlog section-start --name="actual configuration"
cat "${2}"
mrlog section-end --name="actual configuration"
