FROM cfplatformeng/base-image:latest

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/build-tile-config.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/build-tile-config.sh

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/om-helper.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/om-helper.sh

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/upload_and_assign_stemcells.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/upload_and_assign_stemcells.sh

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/install-tile.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/install-tile.sh

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/uninstall-tile.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/uninstall-tile.sh

RUN wget \
    https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/master/tools/compare-staged-config.sh \
    --directory-prefix /usr/local/bin
RUN chmod +x /usr/local/bin/compare-staged-config.sh

COPY needs.json /needs.json
COPY scripts/* /scripts/
ENV PATH="/bin/tools:${PATH}"

CMD ["/bin/bash", "-c", "/scripts/pas-test.sh"]