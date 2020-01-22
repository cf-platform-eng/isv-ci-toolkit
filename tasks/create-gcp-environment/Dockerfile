ARG UAA_VERSION=0.10.0
ARG BASE_IMAGE_VERSION=0.0.23

FROM cfplatformeng/uaa:${UAA_VERSION} AS uaa
FROM cfplatformeng/base-image:${BASE_IMAGE_VERSION}

COPY --from=uaa /usr/local/bin/uaa /usr/local/bin/

# Copy files for this test
COPY [ "gips_client.sh", "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/gips_client.sh ${JOB_DIR}/run.sh
