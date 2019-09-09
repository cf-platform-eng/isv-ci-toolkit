#!/bin/bash

set -ueo pipefail

needs check

echo "Enabling BOSH post-deploy scripts in the BOSH director"
om configure-director \
    --config <(om staged-director-config) \
    --ops-file <(echo '- {type: replace, path: /properties-configuration/director_configuration/post_deploy_enabled, value: true}')

echo "Applying changes"
om apply-changes
