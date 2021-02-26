#!/usr/bin/env bash

function show_image_dependencies() {
  mrlog section --name="show image dependencies" -- cat /root/dependencies.log
}

function check_needs() {
  mrlog section --name="check needs" \
    --on-failure="Needs check indicated one or more needs were not satisfied" \
    --on-success="Needs check successfully found all the requirements for this test" \
    -- needs check
}

function setup_om() {
  if [ -z "${OM_TARGET}" ] ; then
    OM_TARGET=$(jq -r .ops_manager.url /input/environment.json)
    OM_USERNAME=$(jq -r .ops_manager.username /input/environment.json)
    OM_PASSWORD=$(jq -r .ops_manager.password /input/environment.json)
    export OM_TARGET OM_USERNAME OM_PASSWORD
  fi
}

function enable_apps_manager_errand() {
  set -e
  mrlog section --name="enable Apps Manager errand" \
    --on-failure="Failed to enable the Apps Manager errand" \
    --on-success="Apps Manager errand enabled" \
    -- om configure-product \
       --config <(om staged-config --product-name cf) \
       --ops-file <(echo '- {type: replace, path: /errand-config/push-apps-manager/post-deploy-state, value: true}')

  mrlog section --name="deploy CF with Apps Manager" \
    --on-failure="Failed to redeploy cf" \
    --on-success="CF redeployed with Apps Manager" \
    -- om apply-changes --product-name cf
}

function show_admin_credentials() {
  mrlog section --name="show apps manager admin credentials" \
    --on-failure="Failed to get admin credentials" \
    -- om credentials --product-name cf --credential-reference .uaa.admin_credentials
}
