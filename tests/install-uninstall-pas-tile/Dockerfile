FROM cfplatformeng/marman:latest         AS marman
FROM cfplatformeng/mrlog:latest          AS mrlog
FROM cfplatformeng/needs:latest          AS needs
FROM cfplatformeng/om:latest             AS om
FROM cfplatformeng/pivnet:latest         AS pivnet
FROM cfplatformeng/tileinspect:latest    AS tileinspect
FROM cfplatformeng/isv-ci-toolkit:latest AS tools

# Build the test image
FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=marman /usr/local/bin/marman /usr/local/bin/
COPY --from=mrlog /usr/local/bin/mrlog /usr/local/bin/
COPY --from=needs /usr/local/bin/needs /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
COPY --from=pivnet /usr/local/bin/pivnet /usr/local/bin/
COPY --from=tileinspect /usr/local/bin/tileinspect /usr/local/bin/
COPY --from=tools /usr/local/bin/*.sh /usr/local/bin/

# Copy files for this test
COPY [ "needs.json", "run.sh", "/test/" ]
RUN chmod a+x /test/run.sh
WORKDIR /test

CMD ["/bin/bash", "-c", "/test/run.sh"]
