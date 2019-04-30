FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

COPY check.sh .
COPY test.sh .
CMD ["/bin/bash", "-c", "./check.sh && ./test.sh"]