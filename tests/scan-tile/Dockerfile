FROM python:3.5-slim AS pipfile
RUN pip install pipenv

COPY [ "Pipfile", "Pipfile.lock", "/tmp/" ]
RUN cd /tmp && pipenv lock --requirements > requirements.txt

FROM cfplatformeng/base-image
RUN apt-get update && apt-get install -y python3 python3-pip

WORKDIR /test

COPY --from=pipfile /tmp/requirements.txt /test
RUN pip install -r /test/requirements.txt

COPY [ "scan-rules.yml", "scan_tile.py", "/test/" ]

CMD [ "python", "scan_tile.py", "--metadata", "--scan", "/test/scan-rules.yml", "/input/tile.pivotal" ]
