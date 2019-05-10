FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

COPY temp/configkube /test/
COPY test/* /test/
CMD ["/bin/bash", "-c", "cd /test && source commands.sh && run"]