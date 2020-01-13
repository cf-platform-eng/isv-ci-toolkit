ARG MRLOG_VERSION=latest
ARG NEEDS_VERSION=latest

FROM cfplatformeng/mrlog:${MRLOG_VERSION} as mrlog
FROM cfplatformeng/needs:${NEEDS_VERSION} as needs
FROM ubuntu

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
        python-pip \
        vim.tiny \
        wget && \
    rm -rf /var/lib/apt/lists/* && \
    pip install yq

WORKDIR /job
