FROM cfplatformeng/mrlog:latest          AS mrlog
FROM cfplatformeng/needs:latest          AS needs
FROM cfplatformeng/uaa:latest            AS uaa

FROM cfplatformeng/base-image:latest

# Copy binaries from dependent images
COPY --from=mrlog /usr/local/bin/mrlog /usr/local/bin/
COPY --from=needs /usr/local/bin/needs /usr/local/bin/
COPY --from=uaa /usr/local/bin/uaa /usr/local/bin/

# Copy files for this test
COPY [ "needs.json", "run.sh", "steps.sh", "teardown.sh", "/task/" ]
RUN chmod a+x /task/run.sh /task/teardown.sh
WORKDIR /task

CMD ["/bin/bash", "-c", "/task/run.sh"]