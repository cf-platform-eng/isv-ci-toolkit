FROM projects.registry.vmware.com/tanzu_isv_engineering/om:7.1.2 AS om

FROM projects.registry.vmware.com/tanzu_isv_engineering/base-image:0.0.47
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
