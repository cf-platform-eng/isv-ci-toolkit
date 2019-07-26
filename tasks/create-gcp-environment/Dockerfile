FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

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

# Copy tileinspect
COPY temp/tileinspect /usr/local/bin/tileinspect
RUN chmod +x /usr/local/bin/tileinspect

# Copy scripts
COPY ./*.sh ./
RUN chmod +x ./*.sh

CMD ["/bin/bash", "-c", "./runner.sh" ]
