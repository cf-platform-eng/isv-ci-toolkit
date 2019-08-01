FROM ubuntu:xenial
LABEL maintainer="Pivotal Platform Engineering ISV-CI Team <cf-isv-dashboard@pivotal.io>"

ARG GITHUB_TOKEN
ARG PIVNET_TOKEN
ARG BASE_IMAGE_DEPENDENCIES_FILE=/root/base-image-dependencies.log

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

RUN wget https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/log-dependencies.sh --directory-prefix /usr/local/bin && \
    chmod +x /usr/local/bin/log-dependencies.sh

RUN wget `curl -sL https://api.github.com/repos/cf-platform-eng/marman/releases/latest | jq -r '.assets[] | select(.name | contains("-linux")) | .browser_download_url'` && \
    mv marman-linux /usr/local/bin/marman && \
    chmod +x /usr/local/bin/marman

# mrlog
RUN marman download-release --owner cf-platform-eng --repo mrlog --filter "mrlog-linux" && \
    mv mrlog-linux /usr/local/bin/mrlog && \
    chmod +x /usr/local/bin/mrlog && \
    mrlog dependency --name mrlog --version $(mrlog version | cut -d" " -f3) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

RUN mrlog dependency --name marman --version $(marman version | cut -d" " -f3) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# bosh
ARG BOSH_CLI_VER=5.5.1
RUN marman download-release --owner cloudfoundry --repo bosh-cli --version "v${BOSH_CLI_VER}" --filter="bosh-cli-${BOSH_CLI_VER}-linux-amd64" && \
    mv "bosh-cli-${BOSH_CLI_VER}-linux-amd64" /usr/local/bin/bosh && \
    chmod +x /usr/local/bin/bosh && \
    mrlog dependency --name bosh-cli --version ${BOSH_CLI_VER} >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# cf
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add - && \
    echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list && \
    apt-get -y update && apt-get -y install cf-cli

# credhub
ARG CREDHUB_CLI_VER=2.5.2
RUN marman download-release --owner cloudfoundry-incubator --repo credhub-cli --version "${CREDHUB_CLI_VER}" --filter="credhub-linux-${CREDHUB_CLI_VER}.tgz" && \
    tar xvzf credhub-linux-${CREDHUB_CLI_VER}.tgz --directory /usr/local/bin && \
    rm credhub-linux-${CREDHUB_CLI_VER}.tgz && \
    mrlog dependency --name credhub-cli --version ${CREDHUB_CLI_VER} >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# helm
ARG HELM_CLI_VER=2.13.1
RUN wget https://get.helm.sh/helm-v${HELM_CLI_VER}-linux-amd64.tar.gz && \
    tar xvzf helm-v${HELM_CLI_VER}-linux-amd64.tar.gz --directory /usr/local/bin && \
    rm helm-v${HELM_CLI_VER}-linux-amd64.tar.gz && \
    mrlog dependency --name helm-cli --version ${HELM_CLI_VER} >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# ksm
ARG KSM_VERSION=0.4.66
RUN marman download-release --owner cf-platform-eng --repo ksm --version ${KSM_VERSION} --filter "ksm-.*\.linux$" && \
    mv ksm-${KSM_VERSION}.linux /usr/local/bin/ksm && \
    chmod +x /usr/local/bin/ksm && \
    mrlog dependency --name ksm-cli --version $(shasum $(which ksm) | cut -f1 -d" ") >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get -y update && apt-get -y install kubectl

# marman
RUN mrlog dependency --name marman --version $(marman version | cut -f3 -d" ") >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# needs
RUN marman download-release --owner cf-platform-eng --repo needs --filter "needs-linux" && \
    mv needs-linux /usr/local/bin/needs && \
    chmod +x /usr/local/bin/needs && \
    mrlog dependency --name needs --version $(needs --version) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# om
RUN wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add - && \
    echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list && \
    apt-get update && apt-get -y install om

# ops-manifest
ARG OPS_MANIFEST_VERSION=2.7.0-internalDev.128
# TODO deal with licensing
RUN marman download-tile --slug pivotal-ops-manifest --version ${OPS_MANIFEST_VERSION} && \
    gem install *.gem && \
    rm *.gem && \
    mrlog dependency --name ops-manifest --version $(gem list | grep ops-manifest | cut -d" " -f2) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# pivnet
ARG PIVNET_CLI_VER=0.0.60
RUN marman download-release --owner pivotal-cf --repo pivnet-cli --version "v${PIVNET_CLI_VER}" --filter "pivnet-linux-amd64-${PIVNET_CLI_VER}" && \
    mv "pivnet-linux-amd64-${PIVNET_CLI_VER}" /usr/local/bin/pivnet && \
    chmod +x /usr/local/bin/pivnet && \
    mrlog dependency --name pivnet-cli --version ${PIVNET_CLI_VER} >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# pks
# TODO deal with licensing
ARG PKS_VERSION=1.4.0
RUN pivnet login --api-token ${PIVNET_TOKEN} && \
    PKS_FILE_NAME=`pivnet product-files --product-slug pivotal-container-service --release-version ${PKS_VERSION} --format=json | jq -r '.[] | select(.name=="PKS CLI - Linux") | .aws_object_key' | xargs basename` && \
    PKS_FILE_ID=`pivnet product-files --product-slug pivotal-container-service --release-version ${PKS_VERSION} --format=json | jq -r '.[] | select(.name=="PKS CLI - Linux") | .id'` && \
    pivnet download-product-files \
        --accept-eula \
        --product-slug pivotal-container-service \
        --release-version ${PKS_VERSION} \
        --product-file-id ${PKS_FILE_ID} && \
    pivnet logout && \
    mv ${PKS_FILE_NAME} /usr/local/bin/pks && \
    chmod +x /usr/local/bin/pks && \
    mrlog dependency --name pks-cli --version $(pks --version | grep "PKS CLI" | cut -d" " -f4) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# pksctl
ARG PKSCTL_VERSION=0.0.522
RUN marman download-release --owner pivotal --repo pe-pixie --version ${PKSCTL_VERSION} --filter "linux$" && \
    mv pksctl-${PKSCTL_VERSION}.linux /usr/local/bin/pksctl && \
    chmod +x /usr/local/bin/pksctl && \
    mrlog dependency --name pksctl --version $(pksctl version | grep "PKSCTL" | cut -d" " -f3) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# tileinspect
RUN marman download-release --owner cf-platform-eng --repo tileinspect --filter "tileinspect-linux" && \
    mv tileinspect-linux /usr/local/bin/tileinspect && \
    chmod +x /usr/local/bin/tileinspect && \
    mrlog dependency --name tileinspect --version $(tileinspect version | cut -d" " -f3) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# uaac
RUN gem install cf-uaac && \
    mrlog dependency --name uaac --version $(uaac -v | cut -d" " -f3) >> ${BASE_IMAGE_DEPENDENCIES_FILE}

# gcloud
RUN export CLOUD_SDK_REPO="cloud-sdk-xenial" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y && \
    eval "$(gcloud version --format json | jq -r 'to_entries[] | "mrlog dependency --name gcloud-\(.key) --version \(.value) >> ${BASE_IMAGE_DEPENDENCIES_FILE}"')"

# finalize
RUN rm -rf /var/lib/apt/lists/*
