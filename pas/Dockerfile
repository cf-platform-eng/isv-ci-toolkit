FROM ubuntu:xenial

ARG BOSH_CLI_VER=5.4.0

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

# Get the CF CLI
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add -
RUN echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list
RUN apt-get -y update
RUN apt-get -y install cf-cli

# Get OM cli
RUN wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
RUN echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
RUN apt-get update
RUN apt-get install om

# UAAC
RUN apt-get -y install ruby ruby-dev openssl libssl-dev
RUN gem install cf-uaac