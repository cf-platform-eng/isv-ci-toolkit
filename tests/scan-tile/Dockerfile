FROM mirror.gcr.io/python:3.9.1-alpine AS pipfile
RUN pip install pipenv

COPY [ "Pipfile", "Pipfile.lock", "/tmp/" ]
RUN cd /tmp && pipenv requirements > requirements.txt

FROM mirror.gcr.io/python:3.9.1-alpine

WORKDIR /test

COPY --from=pipfile /tmp/requirements.txt /test
RUN pip install -r /test/requirements.txt

COPY [ "scan-rules.yml", "scan_tile.py", "/test/" ]

CMD [ "python", "scan_tile.py", "--metadata", "--scan", "/test/scan-rules.yml", "/input/tile.pivotal" ]
