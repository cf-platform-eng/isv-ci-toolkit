FROM ubuntu:xenial
LABEL maintainer="Pivotal Platform Engineering ISV-CI Team <cf-isv-dashboard@pivotal.io>"

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

VOLUME /input /output /tools
RUN mkdir /task
RUN mkdir /test
ENV PATH="/bin/tools:${PATH}"
