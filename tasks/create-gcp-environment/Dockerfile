FROM cfplatformeng/uaa:0.10.0 AS uaa
FROM cfplatformeng/base-image:0.0.23

COPY --from=uaa /usr/local/bin/uaa /usr/local/bin/

# Copy files for this test
COPY [ "gips_client.sh", "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/gips_client.sh ${JOB_DIR}/run.sh
