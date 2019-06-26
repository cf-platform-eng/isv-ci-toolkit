FROM ubuntu:xenial

RUN apt-get -y update --fix-missing

# Default Tools
RUN apt-get -y install \
    build-essential \
    apt-transport-https \
    curl \
    wget \
    less \
    git \
    jq \
    vim.tiny \
    ruby \
    ruby-dev \
    openssl \
    libssl-dev \
    python-pip

RUN pip install yq


RUN gem install bundler

# bosh
ARG BOSH_CLI_VER=5.4.0
RUN wget "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_CLI_VER}/bosh-cli-${BOSH_CLI_VER}-linux-amd64"
RUN mv "bosh-cli-${BOSH_CLI_VER}-linux-amd64" /usr/local/bin/bosh
RUN chmod +x /usr/local/bin/bosh

# cf
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add -
RUN echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list
RUN apt-get -y update && apt-get -y install cf-cli

# credhub
ARG CREDHUB_CLI_VER=2.2.1
RUN wget "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_CLI_VER}/credhub-linux-${CREDHUB_CLI_VER}.tgz"
RUN tar zxf credhub-linux-${CREDHUB_CLI_VER}.tgz --directory /usr/local/bin
RUN chmod +x /usr/local/bin/credhub
RUN rm credhub-linux-${CREDHUB_CLI_VER}.tgz

# helm
ARG HELM_CLI_VER=2.13.1
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_CLI_VER}-linux-amd64.tar.gz
RUN tar xvzf helm-v${HELM_CLI_VER}-linux-amd64.tar.gz && rm helm-v${HELM_CLI_VER}-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin
RUN mv linux-amd64/tiller /usr/local/bin

# ksm
ARG KSM_CLI_PATH
COPY ${KSM_CLI_PATH} /usr/local/bin/ksm
RUN chmod +x /usr/local/bin/ksm

# kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get -y update && apt-get -y install kubectl

# marman
# TODO deal with licensing
ARG MARMAN_PATH
COPY ${MARMAN_PATH} /usr/local/bin/marman
RUN chmod +x /usr/local/bin/marman

# om
RUN wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
RUN echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
RUN apt-get update && apt-get -y install om

# ops-manifest
# TODO deal with licensing
ARG OPS_MANIFEST_PATH
COPY ${OPS_MANIFEST_PATH} ops-manifest.gem
RUN gem install ops-manifest.gem && rm ops-manifest.gem

# pivnet
ARG PIVNET_CLI_VER=0.0.58
RUN wget "https://github.com/pivotal-cf/pivnet-cli/releases/download/v${PIVNET_CLI_VER}/pivnet-linux-amd64-${PIVNET_CLI_VER}"
RUN mv pivnet-linux-amd64-${PIVNET_CLI_VER} /usr/local/bin/pivnet
RUN chmod +x /usr/local/bin/pivnet

# pks
# TODO deal with licensing
ARG PKS_CLI_PATH
COPY ${PKS_CLI_PATH} /usr/local/bin/pks
RUN chmod +x /usr/local/bin/pks

# pksctl
ARG PKSCTL_PATH
COPY ${PKSCTL_PATH} /usr/local/bin/pksctl
RUN chmod +x /usr/local/bin/pksctl

# tileinspect
ARG TILE_INSPECT_PATH
COPY ${TILE_INSPECT_PATH} /usr/local/bin/tileinspect
RUN chmod +x /usr/local/bin/tileinspect

# uaac
RUN gem install cf-uaac

# gcloud
RUN export CLOUD_SDK_REPO="cloud-sdk-xenial" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y

# finalize
RUN rm -rf /var/lib/apt/lists/*


