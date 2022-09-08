FROM projects.registry.vmware.com/tanzu_isv_engineering/mrlog:0.2.10 as mrlog
FROM projects.registry.vmware.com/tanzu_isv_engineering/needs:0.12.7 as needs
FROM harbor-repo.vmware.com/dockerhub-proxy-cache/library/ubuntu

COPY --from=mrlog /usr/local/bin/mrlog /usr/local/bin/

COPY --from=needs /usr/local/bin/needs /usr/local/bin/

LABEL maintainer="VMware Tanzu ISV-CI Team <cf-isv-dashboard@pivotal.io>"
VOLUME /input /output /job

ENV INPUT_DIR=/input
ENV OUTPUT_DIR=/output
ENV JOB_DIR=/job

RUN apt-get update --fix-missing && \
    apt-get -y install \
        apt-transport-https \
        build-essential \
        curl \
        git \
        jq \
        less \
        python3-pip \
        vim.tiny \
        wget && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install yq

WORKDIR /job

# Installed dependencies are not in the CN-JEB spec
ARG DEPENDENCIES_FILE=/root/dependencies.log
RUN mrlog dependency --type binary --name mrlog --version $(mrlog version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name needs --version $(needs --version) >> ${DEPENDENCIES_FILE}

COPY [ "jeb.sh", "/root/" ]
RUN chmod a+x /root/jeb.sh

ENTRYPOINT ["/root/jeb.sh"]
CMD ["run"]
