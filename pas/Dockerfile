FROM ubuntu:xenial

ARG BOSH_CLI_VER=5.4.0
ARG CREDHUB_CLI_VER=2.2.1
ARG PIVNET_CLI_VER=0.0.55

RUN apt-get -y update

# Default Tools
RUN apt-get -y install \
    build-essential \
    apt-transport-https \
    curl \
    wget \
    less \
    git \
    jq

# BOSH
RUN wget "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_CLI_VER}/bosh-cli-${BOSH_CLI_VER}-linux-amd64"
RUN mv "bosh-cli-${BOSH_CLI_VER}-linux-amd64" /usr/local/bin/bosh
RUN chmod +x /usr/local/bin/bosh

# CF CLI
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add -
RUN echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list
RUN apt-get -y update
RUN apt-get -y install cf-cli

# OM CLI
RUN wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
RUN echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
RUN apt-get update
RUN apt-get install om

# PivNet CLI
RUN wget "https://github.com/pivotal-cf/pivnet-cli/releases/download/v${PIVNET_CLI_VER}/pivnet-linux-amd64-${PIVNET_CLI_VER}"
RUN mv pivnet-linux-amd64-${PIVNET_CLI_VER} /usr/local/bin/pivnet
RUN chmod +x /usr/local/bin/pivnet

# Credhub CLI
RUN wget "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_CLI_VER}/credhub-linux-${CREDHUB_CLI_VER}.tgz"
RUN tar zxf credhub-linux-${CREDHUB_CLI_VER}.tgz --directory /usr/local/bin
RUN chmod +x /usr/local/bin/credhub
RUN rm credhub-linux-${CREDHUB_CLI_VER}.tgz

# UAAC
RUN apt-get -y install ruby ruby-dev openssl libssl-dev
RUN gem install cf-uaac