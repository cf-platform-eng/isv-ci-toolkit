FROM ubuntu:xenial

ARG HELM_VER=2.12.1

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
    vim.tiny

WORKDIR /install/

# kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get -y update
RUN apt-get install -y kubectl
RUN echo "alias k=kubectl" >> ${HOME}/.bashrc

# helm cli
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VER}-linux-amd64.tar.gz
RUN tar xvzf helm-v${HELM_VER}-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin
RUN mv linux-amd64/tiller /usr/local/bin

WORKDIR /test/
RUN rm -rf /install

# pks cli
# TODO deal with licensing
COPY temp/pks /usr/local/bin/pks
RUN chmod +x /usr/local/bin/pks

# bazaar
# TODO deal with licensing
COPY temp/bazaar /usr/local/bin/bazaar
RUN chmod +x /usr/local/bin/bazaar

# kls
# TODO deal with licensing
COPY temp/kls /usr/local/bin/kls
RUN chmod +x /usr/local/bin/kls

COPY test/* /test/
CMD ["/bin/bash", "-c", "cd /test && source commands.sh && run"]