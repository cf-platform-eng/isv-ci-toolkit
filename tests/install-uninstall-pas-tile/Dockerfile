ARG marman_image=us-west1-docker.pkg.dev/isv-tile-partners/tanzu-isv-engineering/marman:0.5.0
ARG om_image=us-west1-docker.pkg.dev/isv-tile-partners/tanzu-isv-engineering/om:7.8.2
ARG pivnet_image=us-west1-docker.pkg.dev/isv-tile-partners/tanzu-isv-engineering/pivnet:3.0.1
ARG tileinspect_image=us-west1-docker.pkg.dev/isv-tile-partners/tanzu-isv-engineering/tileinspect:0.5.15
ARG cf_image=us-west1-docker.pkg.dev/isv-tile-partners/tanzu-isv-engineering/cf:8.5.0
ARG toolkit_image=us-west1-docker.pkg.dev/isv-tile-partners/tanzu-isv-engineering/isv-ci-toolkit:0.0.30
ARG base_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/base-image:0.0.62

IMAGE_ARG_marman_image
IMAGE_ARG_om_image
IMAGE_ARG_pivnet_image
IMAGE_ARG_tileinspect_image
IMAGE_ARG_cf_image
IMAGE_ARG_toolkit_image
IMAGE_ARG_base_image

FROM ${marman_image} as marman
FROM ${om_image} as om
FROM ${pivnet_image}  as pivnet
FROM ${tileinspect_image}  as tileinspect
FROM ${cf_image} as cf
FROM ${toolkit_image} as toolkit

FROM ${base_image}

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
