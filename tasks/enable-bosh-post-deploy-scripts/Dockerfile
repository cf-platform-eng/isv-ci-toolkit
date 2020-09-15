FROM cfplatformeng/om:6.3.0  AS om

FROM cfplatformeng/base-image:0.0.39
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "needs.json", "run.sh", "${JOB_DIR}/" ]
