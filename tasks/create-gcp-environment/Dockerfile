FROM cfplatformeng/mrlog:latest          AS mrlog
FROM cfplatformeng/needs:latest          AS needs

FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=mrlog /usr/local/bin/mrlog /usr/local/bin/
COPY --from=needs /usr/local/bin/needs /usr/local/bin/

# Install cf-uaac ruby gem
RUN apt-get update --fix-missing && \
    apt-get -y install \
        ruby \
        ruby-dev && \
    rm -rf /var/lib/apt/lists/* && \
    gem install cf-uaac

# Copy files for this test
COPY [ "gips_client.sh", "needs.json", "run.sh", "/task/" ]
RUN chmod a+x /task/gips_client.sh /task/run.sh
WORKDIR /task

CMD ["/bin/bash", "-c", "/task/run.sh"]