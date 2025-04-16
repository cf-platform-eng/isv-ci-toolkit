ARG om_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/om:7.7.0
ARG base_image=tas-ecosystem-docker-prod-local.usw1.packages.broadcom.com/tanzu-isv-engineering/base-image:0.0.53

FROM ${om_image} AS om
FROM ${base_image}

ARG DEPENDENCIES_FILE=/root/dependencies.log

COPY --from=om /usr/local/bin/om /usr/local/bin/
RUN mrlog dependency --type binary --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE}

COPY [ "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
