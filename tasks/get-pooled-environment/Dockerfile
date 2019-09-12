FROM cfplatformeng/needs:latest AS needs
FROM cfplatformeng/marman       AS fetch-smith
ARG GITHUB_TOKEN
ARG SMITH_CLI_VER
RUN if [ -z "${SMITH_CLI_VER}" ] ; then \
        marman download-release --owner pivotal --repo smith --filter "smith_linux" ; \
    else \
        marman download-release --owner pivotal --repo smith --version "${SMITH_CLI_VER}" --filter "smith_linux" ; \
    fi
RUN tar zxvf smith_linux*.tar.gz
RUN mv smith /usr/local/bin

FROM cfplatformeng/base-image:latest

LABEL maintainer="Pivotal Platform Engineering ISV-CI Team <cf-isv-dashboard@pivotal.io>"

COPY --from=fetch-smith /usr/local/bin/smith /usr/local/bin
COPY --from=needs /usr/local/bin/needs /usr/local/bin/

# Copy files for this test
COPY [ "needs.json", "run.sh", "/task/" ]
RUN chmod a+x /task/run.sh
WORKDIR /task

CMD ["/bin/bash", "-c", "/task/run.sh"]
