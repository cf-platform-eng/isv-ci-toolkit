FROM ubuntu:xenial

RUN apt-get -y update
RUN apt-get -y install \
    python \
    python-pip \
    software-properties-common \
    virtualenv \
    unzip \
    zip \
    libxi6 \
    libgconf-2-4 \
    libxml2-dev \
    libxslt1-dev \
    less \
    vim \
    wget \
    apt-transport-https \
    ca-certificates \
    jq

# Get the CF CLI
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add -
RUN echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list
RUN apt-get -y update
RUN apt-get -y install cf-cli

ADD om-linux /usr/local/bin/om
RUN chmod +x /usr/local/bin/om