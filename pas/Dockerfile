FROM ubuntu:xenial

RUN apt-get -y update

# Default Tools
RUN apt-get -y install \
    apt-transport-https \
    curl \
    wget \
    jq

# BOSH
RUN wget https://github.com/cloudfoundry/bosh-cli/releases/download/v5.4.0/bosh-cli-5.4.0-linux-amd64
RUN mv bosh-cli-5.4.0-linux-amd64 /usr/local/bin/bosh
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