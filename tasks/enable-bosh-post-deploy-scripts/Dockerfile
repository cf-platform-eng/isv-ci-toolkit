FROM cfplatformeng/toolkit-pas

CMD [ \
    "/bin/bash", \
    "-c", \
    " \
    echo \"Enabling BOSH post-deploy scripts in the BOSH director\" && \
    om -k configure-director --config <(om -k staged-director-config) --ops-file <(echo '- {type: replace, path: /properties-configuration/director_configuration/post_deploy_enabled, value: true}') && \
    echo \"Applying changes\" && \
    om -k apply-changes \
    " \
    ]
