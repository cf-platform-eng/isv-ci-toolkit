FROM cfplatformeng/marman:latest         AS marman
FROM cfplatformeng/mrlog:latest          AS mrlog
FROM cfplatformeng/needs:latest          AS needs
FROM cfplatformeng/om:latest             AS om
FROM cfplatformeng/isv-ci-toolkit:latest AS tools

# Build the test image
FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=marman /usr/local/bin/marman /usr/local/bin/
COPY --from=mrlog /usr/local/bin/mrlog /usr/local/bin/
COPY --from=needs /usr/local/bin/needs /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
COPY --from=tools /usr/local/bin/*.sh /usr/local/bin/

RUN apt-get update && apt-get install -y gettext-base node-semver && rm -rf /var/lib/apt/lists/*

# Copy files for this test
COPY [ "add-cf.yml", "elastic-runtime.srt.azure.json", "elastic-runtime.srt.gcp.json", "needs.json", "run.sh", "steps.sh", "/task/" ]

RUN chmod a+x /task/*.sh
WORKDIR /task

CMD ["/bin/bash", "-c", "/task/run.sh"]
