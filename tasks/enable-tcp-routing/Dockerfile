FROM cfplatformeng/om:6.3.0  AS om
FROM cfplatformeng/cf:7.1.0 AS cf

FROM cfplatformeng/base-image:0.0.39
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=cf /usr/local/bin/cf /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name cf-cli --version $(cf version | cut -d" " -f3) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "config.yml", "needs.json", "run.sh", "${JOB_DIR}/" ]
