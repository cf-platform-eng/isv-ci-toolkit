FROM cfplatformeng/marman:0.4.4          AS marman
FROM cfplatformeng/om:7.0.0              AS om
FROM cfplatformeng/isv-ci-toolkit:0.0.24 AS tools

FROM cfplatformeng/base-image:0.0.41
ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=marman /usr/local/bin/marman /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
COPY --from=tools /usr/local/bin/*.sh /usr/local/bin/
RUN mrlog dependency --type binary --name marman --version $(marman version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y gettext-base node-semver && \
    rm -rf /var/lib/apt/lists/*

COPY [ "add-cf.yml", "elastic-runtime.srt.azure.json", "elastic-runtime.srt.gcp.json", "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
