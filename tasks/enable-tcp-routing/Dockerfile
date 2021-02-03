FROM harbor-repo.vmware.com/partner_engineering/om:7.1.2 AS om
FROM harbor-repo.vmware.com/partner_engineering/cf:7.2.0 AS cf

FROM harbor-repo.vmware.com/partner_engineering/base-image:0.0.47
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=cf /usr/local/bin/cf /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name cf-cli --version $(cf version | cut -d" " -f3) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "config.yml", "needs.json", "run.sh", "${JOB_DIR}/" ]
