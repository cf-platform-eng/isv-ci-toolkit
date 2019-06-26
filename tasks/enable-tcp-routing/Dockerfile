FROM cfplatformeng/toolkit-pas

# Assumptions
# * 

COPY config.yml config.yml

CMD [ \
    "/bin/bash", \
    "-c", \
    " \
    echo \"Configuring environment with tcp routing\" && \
    export TCP_ROUTER_POOL=$( cat test-input-files/environment.json | jq -r '.tcp_router_pool' ) && \
    echo \"  Using TCP_ROUTER_POOL: $TCP_ROUTER_POOL\" && \
    sed -i -e s/ELB_NAME/$TCP_ROUTER_POOL/g config.yml && \
    om configure-product --config config.yml && \
    echo \"  Applying changes...\" && \
    om apply-changes && \
    export CF_API=https://api.$( cat test-input-files/environment.json | jq -r '.sys_domain' ) && \
    export CF_USERNAME=$( om credentials -p cf -c .uaa.admin_credentials -f identity ) && \
    export CF_PASSWORD=$( om credentials -p cf -c .uaa.admin_credentials -f password ) && \
    cf login --skip-ssl-validation -a $CF_API -o system -u $CF_USERNAME -p $CF_PASSWORD && \
    export TCP_DOMAIN=$( cat test-input-files/environment.json | jq -r '.tcp_domain' ) && \
    export SHARED_DOMAIN_EXISTS=$( cf domains | grep $TCP_DOMAIN) && \
    SHARED_DOMAIN=$(cf domains | grep $TCP_DOMAIN); if [ -z \"$SHARED_DOMAIN\"]; \
        then cf create-shared-domain $TCP_DOMAIN --router-group default-tcp; \
        else echo \"Domain already exists\"; fi && \
    echo \"  Updating quota...\" && \
    cf update-quota default --reserved-route-ports 99 \
    " \
    ]
