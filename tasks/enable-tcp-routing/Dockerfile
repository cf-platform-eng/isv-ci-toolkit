FROM projects.registry.vmware.com/tanzu_isv_engineering/om:7.7.0 AS om
FROM projects.registry.vmware.com/tanzu_isv_engineering/cf:8.4.0 AS cf

FROM projects.registry.vmware.com/tanzu_isv_engineering/base-image:0.0.47
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=cf /usr/local/bin/cf /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name cf-cli --version $(cf version | cut -d" " -f3) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "config.yml", "needs.json", "run.sh", "${JOB_DIR}/" ]
