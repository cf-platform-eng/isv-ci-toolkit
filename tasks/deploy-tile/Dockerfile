FROM harbor-repo.vmware.com/partner_engineering/marman:0.4.5 as marman
FROM harbor-repo.vmware.com/partner_engineering/om:7.1.2 AS om
FROM harbor-repo.vmware.com/partner_engineering/tileinspect:0.5.11 AS tileinspect
FROM cfplatharbor-repo.vmware.com/partner_engineeringformeng/isv-ci-toolkit:0.0.25 AS tools

FROM harbor-repo.vmware.com/partner_engineering/base-image:0.0.47
ARG DEPENDENCIES_FILE=/root/dependencies.log

# Copy binaries from dependent images
COPY --from=marman /usr/local/bin/marman /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
COPY --from=tileinspect /usr/local/bin/tileinspect /usr/local/bin/
COPY --from=tools /usr/local/bin/*.sh /usr/local/bin/

# Log dependency versions
RUN mrlog dependency --type binary --name marman --version $(marman version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name tileinspect --version $(tileinspect version | cut -d" " -f3) >> ${DEPENDENCIES_FILE}

ENV TILE_PATH=/input/tile.pivotal
ENV TILE_CONFIG_PATH=/input/config.json

# Copy files for this test
COPY [ "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]

# source the steps.sh commands, to simplify interactive development.
RUN ["/bin/bash", "-c", "echo \"\nsource ${JOB_DIR}/steps.sh\n\" >> ~/.bashrc"]
