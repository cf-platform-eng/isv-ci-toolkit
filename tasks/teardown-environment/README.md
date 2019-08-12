# Teardown Environment

This task is used to destroy an environment that was created using [Paver](https://github.com/pivotal/paver) (typically via the `create-gcp-environment` task). This will typically be the final chain in a series of tasks and a test to clean up the resources created to run the test.

## Prerequisites

The following is required to run this task:

* Docker
* The environment name
* GIPS client id
* GIPS client secret

## Running

Create a file to contain the credentials with the following format:

```json
{
    "client_id": "GIPS CLIENT ID",
    "client_secret": "GIPS CLIENT SECRET"
}
```

The following environment variables are required:

* `CRED_FILE_PATH` - The path to the credentials json file you created above.
* `INSTALLATION_NAME` - The name of the environment to tear down.

The following environment variables are optional:

* `GIPS_ADDRESS` - The address of GIPS to send the environment deletion request (defaults to `podium.tls.cfapps.io`).
* `GIPS_UAA_ADDRESS` - The address of GIPS' UAA server, used for authentication (defaults to `gips-prod.login.run.pivotal.io`).

### Running with Makefile

```bash
$ export CRED_FILE_PATH=/path/to/credentials.json
$ export INSTALLATION_NAME=sneakysquirrel123
$ make run
```

### Running with docker

```bash
$ export CRED_FILE_PATH=/path/to/credentials.json
$ export INSTALLATION_NAME=sneakysquirrel123
$ docker run -it \
    -e INSTALLATION_NAME \
    -e CRED_FILE=$(shell basename "${CRED_FILE_PATH}") \
    -e GIPS_ADDRESS \
    -e GIPS_UAA_ADDRESS \
    -v $(shell dirname "${CRED_FILE_PATH}"):/input \
    gcr.io/fe-rabbit-mq-tile-ci/teardown-environment
```
