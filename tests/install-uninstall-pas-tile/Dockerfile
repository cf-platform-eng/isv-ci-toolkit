FROM projects.registry.vmware.com/tanzu_isv_engineering/marman:0.4.8 as marman
FROM projects.registry.vmware.com/tanzu_isv_engineering/om:7.7.0 as om
FROM projects.registry.vmware.com/tanzu_isv_engineering/pivnet:3.0.1 as pivnet
FROM projects.registry.vmware.com/tanzu_isv_engineering/tileinspect:0.5.15 as tileinspect
FROM projects.registry.vmware.com/tanzu_isv_engineering/cf:8.5.0 as cf
FROM projects.registry.vmware.com/tanzu_isv_engineering/isv-ci-toolkit:0.0.30 as toolkit

FROM projects.registry.vmware.com/tanzu_isv_engineering/base-image:0.0.54
ARG DEPENDENCIES_FILE=/root/dependencies.log

# Copy binaries from dependent images
COPY --from=marman         /usr/local/bin/marman        /usr/local/bin/
COPY --from=om             /usr/local/bin/om            /usr/local/bin/
COPY --from=pivnet         /usr/local/bin/pivnet        /usr/local/bin/
COPY --from=tileinspect    /usr/local/bin/tileinspect   /usr/local/bin/
COPY --from=cf             /usr/local/bin/cf            /usr/local/bin/
COPY --from=toolkit        /usr/local/bin/*.sh          /usr/local/bin/

# Log dependency versions
RUN mrlog dependency --type binary --name marman --version $(marman version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name pivnet-cli --version $(pivnet version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name tileinspect --version $(tileinspect version | cut -d" " -f3) >> ${DEPENDENCIES_FILE}  && \
    mrlog dependency --type binary --name cf-cli --version $(cf version | cut -d" " -f3) >> ${DEPENDENCIES_FILE}

ENV TILE_PATH=/input/tile.pivotal
ENV TILE_CONFIG_PATH=/input/config.json

# Copy files for this test
COPY [ "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]

# source the steps.sh commands, to simplify interactive development.
RUN ["/bin/bash", "-c", "echo \"\nsource ${JOB_DIR}/steps.sh\n\" >> ~/.bashrc"]
