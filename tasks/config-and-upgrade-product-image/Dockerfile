FROM cfplatformeng/marman:0.4.4          AS marman
FROM cfplatformeng/om:6.5.0              AS om
FROM cfplatformeng/isv-ci-toolkit:0.0.24 AS tools

FROM cfplatformeng/base-image:0.0.44

# Copy binaries from dependent images
COPY --from=marman /usr/local/bin/marman /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
COPY --from=tools /usr/local/bin/*.sh /usr/local/bin/

RUN apt-get update && apt-get install -y gettext-base node-semver && rm -rf /var/lib/apt/lists/*

# Copy files for this test
COPY ["needs.json", "run.sh", "${JOB_DIR}/"]
RUN chmod a+x ${JOB_DIR}/*.sh
