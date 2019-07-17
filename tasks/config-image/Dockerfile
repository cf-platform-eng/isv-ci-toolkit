FROM ubuntu:xenial

RUN apt-get -y update --fix-missing

# Default Tools
RUN apt-get -y install \
    wget \
    jq \
    gettext-base \
    node-semver \
    vim.tiny

# Install om
RUN wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
RUN echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
RUN apt-get update && apt-get -y install om

# Copy marman
COPY temp/marman /usr/local/bin/marman
RUN chmod +x /usr/local/bin/marman

# Copy scripts
COPY ./*.sh ./
RUN chmod +x ./*.sh

CMD ["/bin/bash", "-c", "./runner.sh" ]
