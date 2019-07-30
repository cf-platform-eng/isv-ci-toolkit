FROM gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

COPY *.sh ./
RUN chmod +x *.sh
COPY needs.json ./

CMD ["/bin/bash", "-c", "./runner.sh" ]
