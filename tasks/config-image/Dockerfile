FROM harbor-repo.vmware.com/partner_engineering/marman:0.4.5          AS marman
FROM harbor-repo.vmware.com/partner_engineering/om:7.1.2              AS om
FROM harbor-repo.vmware.com/partner_engineering/isv-ci-toolkit:0.0.25 AS tools

FROM harbor-repo.vmware.com/partner_engineering/base-image:0.0.47
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
