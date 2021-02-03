FROM harbor-repo.vmware.com/partner_engineering/uaa:0.10.0 AS uaa

FROM harbor-repo.vmware.com/partner_engineering/base-image:0.0.47
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=uaa /usr/local/bin/uaa /usr/local/bin/
RUN mrlog dependency --type binary --name uaa --version $(uaa version | cut -f1 -d" ") >> ${DEPENDENCIES_FILE}

COPY [ "needs.json", "run.sh", "steps.sh", "teardown.sh", "${JOB_DIR}/" ]
