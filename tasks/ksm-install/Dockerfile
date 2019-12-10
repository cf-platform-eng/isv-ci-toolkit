FROM cfplatformeng/base-image:latest

ENV INPUT_DIR=/input
ENV OUTPUT_DIR=/input

# Copy binaries from dependent images
COPY --from=cfplatformeng/mrlog:latest          /usr/local/bin/mrlog /usr/local/bin/
COPY --from=cfplatformeng/needs:latest          /usr/local/bin/needs /usr/local/bin/
COPY --from=cfplatformeng/tileinspect:latest    /usr/local/bin/tileinspect /usr/local/bin/

RUN apt-get update && apt-get install -y apt-transport-https && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl

# Log dependency versions
ENV DEPENDENCIES_FILE=/root/dependencies.log

RUN mrlog dependency --type binary --name mrlog --version $(mrlog version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name needs --version $(needs --version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name tileinspect --version $(needs --version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name kubectl --version $(kubectl version | sed -e 's/.*\(GitVersion:".*"\), GitCommit:.*/\1/') >> ${DEPENDENCIES_FILE}

# Copy files for this app
COPY [ "needs.json", "run.sh", "steps.sh", "SERVICE-ACCOUNT.yml", "/test/" ]
RUN chmod a+x /test/run.sh
WORKDIR /test

CMD ["/bin/bash", "-c", "/test/run.sh"]
