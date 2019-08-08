FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

RUN apt-get update && apt-get install -y gettext-base node-semver

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/om-helper.sh \
    --directory-prefix /usr/local/bin

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/upload_and_assign_stemcells.sh \
    --directory-prefix /usr/local/bin

COPY ./*.sh ./
RUN chmod +x ./*.sh

CMD ["/bin/bash", "-c", "./runner.sh" ]
