ARG marman_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/marman:0.4.5
ARG om_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/om:7.7.0
ARG tileinspect_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/tileinspect:0.5.11
ARG isv_ci_toolkit=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/isv-ci-toolkit:0.0.25
ARG base_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/base-image:0.0.53

FROM ${marman_image} as marman
FROM ${om_image} AS om
FROM ${tileinspect_image} AS tileinspect
FROM ${isv_ci_toolkit} AS tools
FROM ${base_image}

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
