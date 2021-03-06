FROM harbor-repo.vmware.com/partner_engineering/base-image:latest

ENV INPUT_DIR=/input
ENV OUTPUT_DIR=/input

# Copy binaries from dependent images
COPY --from=harbor-repo.vmware.com/partner_engineering/mrlog:latest          /usr/local/bin/mrlog /usr/local/bin/
RUN true
COPY --from=harbor-repo.vmware.com/partner_engineering/needs:latest          /usr/local/bin/needs /usr/local/bin/
RUN true
COPY --from=harbor-repo.vmware.com/partner_engineering/marman:latest         /usr/local/bin/marman /usr/local/bin/
RUN true
COPY --from=harbor-repo.vmware.com/partner_engineering/pivnet:latest         /usr/local/bin/pivnet /usr/local/bin/
RUN true
COPY --from=harbor-repo.vmware.com/partner_engineering/tileinspect:latest    /usr/local/bin/tileinspect /usr/local/bin/
RUN true
COPY --from=harbor-repo.vmware.com/partner_engineering/om:latest             /usr/local/bin/om /usr/local/bin/
RUN true
COPY --from=harbor-repo.vmware.com/partner_engineering/isv-ci-toolkit:latest /usr/local/bin/*.sh /usr/local/bin/
RUN true

RUN apt-get update && apt-get install -y apt-transport-https gettext-base
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update -y && \
    apt-get install google-cloud-sdk -y
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update -y && \
    apt-get install -y kubectl

# Log dependency versions
ENV DEPENDENCIES_FILE=/root/dependencies.log

RUN mrlog dependency --type binary --name mrlog --version $(mrlog version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name needs --version $(needs --version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name tileinspect --version $(tileinspect version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name marman --version $(marman version | cut -f3 -d" ") >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name pivnet --version $(pivnet --version) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "Google Cloud SDK" --version $(gcloud version  --format=json | jq -r '."Google Cloud SDK"') >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "gcloud alpha" --version $(gcloud version  --format=json     | jq -r .alpha) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "gcloud beta" --version $(gcloud version  --format=json      | jq -r .beta) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "gcloud bq" --version $(gcloud version  --format=json        | jq -r .bq) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "gcloud core" --version $(gcloud version  --format=json      | jq -r .core) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "gcloud gsutil" --version $(gcloud version  --format=json    | jq -r .gsutil) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name "gcloud kubectl" --version $(gcloud version  --format=json   | jq -r .kubectl) >> ${DEPENDENCIES_FILE} && \
    mrlog dependency --type binary --name kubectl --version $( kubectl version  --client -o json | jq -r .clientVersion.gitVersion )>> ${DEPENDENCIES_FILE}

# Copy files for this app
COPY [ "needs.json", "run.sh", "steps.sh", "SERVICE-ACCOUNT.yml", "ksm-config.template.yml", "/job/"]
COPY ["lib/*", "/job/lib/" ]

RUN ["/bin/bash", "-c", "echo \"\nsource /job/steps.sh\n\" >> ~/.bashrc"]
