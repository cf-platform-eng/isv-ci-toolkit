FROM cfplatformeng/om:4.5.0  AS om
FROM cfplatformeng/base-image:0.0.27

COPY --from=om /usr/local/bin/om /usr/local/bin/

COPY [ "needs.json", "run.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/run.sh
