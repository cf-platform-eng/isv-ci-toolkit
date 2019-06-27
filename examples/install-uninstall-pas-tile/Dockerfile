FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest


RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/166641094-install-pas-ci/tools/om-helper.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/om-helper.sh
RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/166641094-install-pas-ci/tools/upload_and_assign_stemcells.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/upload_and_assign_stemcells.sh

COPY scripts/* /scripts/

CMD ["/bin/bash", "-c", "/scripts/pas-test.sh"]