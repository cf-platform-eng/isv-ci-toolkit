ARG om_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/om:7.7.0 AS om
ARG cf_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/cf:8.7.10 AS cf
ARG base_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/base-image:0.0.53

FROM ${om_image} as om
FROM ${cf_image} as cf
FROM ${base_image}

ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=cf /usr/local/bin/cf /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name cf-cli --version $(cf version | cut -d" " -f3) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "config.yml", "needs.json", "run.sh", "${JOB_DIR}/" ]
