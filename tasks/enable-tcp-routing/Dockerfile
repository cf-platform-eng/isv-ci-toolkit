FROM cfplatformeng/om:4.5.0  AS om
FROM cfplatformeng/cf:6.49.0 AS cf

FROM cfplatformeng/base-image:0.0.26

COPY --from=cf /usr/local/bin/cf /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/

COPY [ "config.yml", "needs.json", "run.sh", "${JOB_DIR}/" ]
RUN chmod a+x ${JOB_DIR}/run.sh
