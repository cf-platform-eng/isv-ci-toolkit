# Create GCP Environment

This task is used to create a GCP environment using [Paver](https://github.com/pivotal/paver). Which will often be the first part in a larger chain of tasks to configure a platform used for testing.

## Prerequisites

The following is required to run this task:

* Docker
* GIPS client id
* GIPS client secret
* GCP service account key

## Running

Create a file to contain the credentials with the following format:

```json
{
    "client_id": "GIPS CLIENT ID",
    "client_secret": "GIPS CLIENT SECRET",
    "service_account_key": {
        ...
        GCP SERVICE ACCOUNT KEY
        ...
    }
}
```

The following environment variables are required:

* `OPS_MAN_VERSION` - The version of OpsManager to be created (e.g. 2.6.2).
* `CRED_FILE_PATH` - The path to the credentials json file you created above.

The following environment variables are optional:

* `GIPS_ADDRESS` - The address of GIPS to send the environment creation request (defaults to `podium.tls.cfapps.io`).
* `GIPS_UAA_ADDRESS` - The address of GIPS' UAA server, used for authentication (defaults to `gips-prod.login.run.pivotal.io`).

### Running with Makefile

```bash
$ export OPS_MAN_VERSION="2.6.2"
$ export CRED_FILE_PATH=/path/to/credentials.json
$ make run
```

### Running with docker

```bash
$ export OPS_MAN_VERSION="2.6.2"
$ export CRED_FILE_PATH=/path/to/credentials.json
$ docker run -it \
    -e OPS_MAN_VERSION \
    -e CRED_FILE=$(shell basename "${CRED_FILE_PATH}") \
    -e GIPS_ADDRESS \
    -e GIPS_UAA_ADDRESS \
    -v $(shell dirname "${CRED_FILE_PATH}"):/input \
    -v `pwd`/output:/output \
    gcr.io/fe-rabbit-mq-tile-ci/create-gcp-environment
```
