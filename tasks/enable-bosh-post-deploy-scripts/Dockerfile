FROM cfplatformeng/base-image:latest

COPY --from=cfplatformeng/needs:latest /usr/local/bin/needs /usr/local/bin/
COPY --from=cfplatformeng/om:latest    /usr/local/bin/om /usr/local/bin/

COPY [ "needs.json", "run.sh", "/task/" ]
RUN chmod a+x /task/run.sh
WORKDIR /task

CMD ["/bin/bash", "-c", "/task/run.sh"]
