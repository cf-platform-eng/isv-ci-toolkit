FROM ubuntu

RUN apt-get -y update --fix-missing

# Default Tools
RUN apt-get -y install \
    wget \
    jq \
    gettext-base \
    node-semver \
    vim.tiny \
    gnupg

# Install om
RUN wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
RUN echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
RUN apt-get update && apt-get -y install om

# Copy marman
COPY --from=cfplatformeng/marman:latest         /usr/local/bin/marman /usr/local/bin/


# Copy tileinspect
COPY --from=cfplatformeng/tileinspect:latest    /usr/local/bin/tileinspect /usr/local/bin/

# Copy scripts
COPY ./*.sh ./
RUN chmod +x ./*.sh

CMD ["/bin/bash", "-c", "./runner.sh" ]
