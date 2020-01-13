ARG MARMAN_VERSION=latest
ARG OM_VERSION=latest
ARG PIVNET_VERSION=latest
ARG TILEINSPECT_VERSION=latest
ARG ISV_CI_TOOLKIT_VERSION=latest
ARG BASE_IMAGE_VERSIOn=latest

FROM cfplatformeng/marman:${MARMAN_VERSION} as marman
FROM cfplatformeng/om:${OM_VERSION} as om
FROM cfplatformeng/pivnet:${PIVNET_VERSION} as pivnet
FROM cfplatformeng/tileinspect:${TILEINSPECT_VERSION} as tileinspect
FROM cfplatformeng/isv-ci-toolkit:${ISV_CI_TOOLKIT_VERSION} as toolkit

FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=marman         /usr/local/bin/marman /usr/local/bin/
COPY --from=om             /usr/local/bin/om /usr/local/bin/
COPY --from=pivnet         /usr/local/bin/pivnet /usr/local/bin/
COPY --from=tileinspect    /usr/local/bin/tileinspect /usr/local/bin/
COPY --from=toolkit        /usr/local/bin/*.sh /usr/local/bin/


# Log dependency versions
ARG DEPENDENCIES_FILE=/root/dependencies.log
RUN mrlog dependency --type binary --name marman --version $(marman version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name pivnet-cli --version $(pivnet version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name tileinspect --version $(tileinspect version | cut -d" " -f3) >> ${DEPENDENCIES_FILE}

# Copy files for this test
COPY [ "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/run.sh


