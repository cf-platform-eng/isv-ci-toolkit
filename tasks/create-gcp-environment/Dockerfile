FROM cfplatformeng/mrlog:latest          AS mrlog
FROM cfplatformeng/needs:latest          AS needs
FROM cfplatformeng/uaa:latest            AS uaa

FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=mrlog /usr/local/bin/mrlog /usr/local/bin/
COPY --from=needs /usr/local/bin/needs /usr/local/bin/
COPY --from=uaa /usr/local/bin/uaa /usr/local/bin/

# Copy files for this test
COPY [ "gips_client.sh", "needs.json", "run.sh", "steps.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/gips_client.sh ${JOB_DIR}/run.sh
