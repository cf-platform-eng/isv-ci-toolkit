FROM cfplatformeng/uaa:0.10.0 AS uaa
FROM cfplatformeng/base-image:0.0.29

COPY --from=uaa /usr/local/bin/uaa /usr/local/bin/

# Copy files for this test
COPY [ "needs.json", "run.sh", "steps.sh", "teardown.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/run.sh ${JOB_DIR}/teardown.sh
