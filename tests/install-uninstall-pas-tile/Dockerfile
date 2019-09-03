FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=cfplatformeng/marman:latest         /usr/local/bin/marman /usr/local/bin/
COPY --from=cfplatformeng/mrlog:latest          /usr/local/bin/mrlog /usr/local/bin/
COPY --from=cfplatformeng/needs:latest          /usr/local/bin/needs /usr/local/bin/
COPY --from=cfplatformeng/om:latest             /usr/local/bin/om /usr/local/bin/
COPY --from=cfplatformeng/pivnet:latest         /usr/local/bin/pivnet /usr/local/bin/
COPY --from=cfplatformeng/tileinspect:latest    /usr/local/bin/tileinspect /usr/local/bin/
COPY --from=cfplatformeng/isv-ci-toolkit:latest /usr/local/bin/*.sh /usr/local/bin/

# Log dependency versions
ARG DEPENDENCIES_FILE=/root/dependencies.log
RUN mrlog dependency --name marman --version $(marman version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --name mrlog --version $(mrlog version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --name needs --version $(needs --version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --name om-cli --version $(om version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --name pivnet-cli --version $(pivnet version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --name tileinspect --version $(tileinspect version | cut -d" " -f3) >> ${DEPENDENCIES_FILE}

# Copy files for this test
COPY [ "needs.json", "run.sh", "/test/" ]
RUN chmod a+x /test/run.sh
WORKDIR /test

CMD ["/bin/bash", "-c", "/test/run.sh"]
