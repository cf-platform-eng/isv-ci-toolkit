#!/bin/bash

set -ueo pipefail

needs check

echo "Configuring environment with tcp routing"
TCP_ROUTER_POOL=$(jq -r '.tcp_router_pool' test-input-files/environment.json)

echo "  Using TCP_ROUTER_POOL: ${TCP_ROUTER_POOL}"
sed -i -e s/ELB_NAME/"${TCP_ROUTER_POOL}"/g config.yml
om configure-product --config config.yml

echo "  Applying changes..."
om apply-changes

CF_API=https://api.$(jq -r '.sys_domain' test-input-files/environment.json)
CF_USERNAME=$(om credentials -p cf -c .uaa.admin_credentials -f identity)
CF_PASSWORD=$(om credentials -p cf -c .uaa.admin_credentials -f password)
cf login --skip-ssl-validation -a "${CF_API}" -o system -u "${CF_USERNAME}" -p "${CF_PASSWORD}"

TCP_DOMAIN=$(jq -r '.tcp_domain' test-input-files/environment.json)
SHARED_DOMAIN=$(cf domains | grep "${TCP_DOMAIN}");

if [ -z "$SHARED_DOMAIN" ] ; then
    cf create-shared-domain "${TCP_DOMAIN}" --router-group default-tcp; \
else
    echo "Domain already exists";
fi

echo "  Updating quota..."
cf update-quota default --reserved-route-ports 99
