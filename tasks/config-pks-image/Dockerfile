FROM cfplatformeng/marman:0.4.2      AS marman
FROM cfplatformeng/om:4.8.0          AS om
FROM cfplatformeng/tileinspect:0.5.8 AS tileinspect

FROM cfplatformeng/base-image:0.0.30

RUN apt-get update && apt-get install -y gettext-base gnupg node-semver && rm -rf /var/lib/apt/lists/*

COPY --from=marman      /usr/local/bin/marman      /usr/local/bin/
COPY --from=om          /usr/local/bin/om          /usr/local/bin/
COPY --from=tileinspect /usr/local/bin/tileinspect /usr/local/bin/

COPY ./*.sh {JOB_DIR}/
RUN chmod a+x ${JOB_DIR}/*.sh
