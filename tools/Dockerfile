FROM mirror.gcr.io/ubuntu

COPY ./*.sh /usr/local/bin/
RUN chmod +x \
    /usr/local/bin/om-helper.sh \
    /usr/local/bin/upload_and_assign_stemcells.sh \
    /usr/local/bin/install-tile.sh \
    /usr/local/bin/uninstall-tile.sh \
    /usr/local/bin/compare-staged-config.sh
