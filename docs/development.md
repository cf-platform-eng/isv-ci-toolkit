# Development

This toolkit contains tests that will be useful for many ISV partner products. However, you may want to add steps to customize your specific integration. This doc will provide two methods for creating your own, customized tests.

## Test basics

Each test image in the ISV-CI toolkit have these things in common:

* A `needs.json` that describes the inputs requirements using [Needs](https://github.com/cf-platform-eng/needs).
* A `steps.sh` script that exports a function for each step in the test.
* A `run.sh` script that runs the test steps. This is the default `CMD` for the Dockerfile.
* A Dockerfile with at least:
  * `COPY [ "needs.json", "run.sh", <any other files>..., "/test/" ]`
  * `WORKDIR /test`
  * `CMD ["/bin/bash", "-c", "/test/run.sh"]`

## Building a test from scratch

TBD

## Extending a test from this toolkit

The tests in this toolkit are designed to be easily extended to add your custom testing.

### Create a new run.sh script

Create a run.sh script that sources the test steps, invokes them and adds your custom testing:

```bash
source ./steps.sh
if ! needs_check            ; then exit 1 ; fi
if ! config_file_check      ; then exit 1 ; fi
if ! log_dependencies       ; then exit 1 ; fi
if ! install_tile           ; then exit 1 ; fi

# At this point, the tile is configured and deployed, so
# add your testing here.

if ! uninstall_tile         ; then exit 1 ; fi
```

### Dockerfile

Make a Dockerfile that inherits from the example test's Dockerfile and copies in your new `run.sh` script:

```Dockerfile
FROM cfplatformeng/install-uninstall-test-image
COPY [ "run.sh", "/test/" ]
```

### Test your test

Validate things work by testing things out with shell:

```bash
$ docker build -t my-isv-ci-test .
$ docker run -it my-isv-ci-test bash
root@5cd0c73b7329:/test# source steps.sh
root@5cd0c73b7329:/test# needs_check
...
```

### Run your test

When the individual steps work well, run the test!

```bash
docker run -it my-isv-ci-test
```
