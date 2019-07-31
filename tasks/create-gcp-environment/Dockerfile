FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

COPY *.sh needs.json ./
RUN chmod +x *.sh

CMD ["/bin/bash", "-c", "./runner.sh" ]
