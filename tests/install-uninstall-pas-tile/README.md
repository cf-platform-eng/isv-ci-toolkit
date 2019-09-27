# Test Install, configure, apply changes, and uninstall a PAS tile

This test will upload, install, stage, configure and uninstall a tile on a Pivotal Cloud Foundry foundation. If at any point a step fails, the test will stop.

## Step by step

Here are the steps for running the install-uninstall test.

### 1. Git the repo, enter the test directory

```bash
$ git clone git@github.com:cf-platform-eng/isv-ci-toolkit.git
$ cd isv-ci-toolkit/tests/install-uninstall-pas-tile
```

### 2. Locate the the .pivotal integration that will be tested

The environment variable `TILE_PATH` locates the .pivotal file that contains the integration to test.

For example, if the .pivotal file is at */home/me/workspace/my-tile.pivotal*:

```bash
$ export TILE_PATH=/home/me/workspace/my-tile.pivotal
```

### 3. Create a configuration to test the integration against

The test will configure the integration with the provided settings and run apply changes to make sure the integration configures and installs. It is up to the integration developer to create a configuration appropriate for their integration.

[Tips for building a valid config file](https://github.com/cf-platform-eng/isv-ci-toolkit/blob/master/docs/creating-tile-configs.md)

A properties file follows the form:

```json
{
    "product-properties": {
        ".properties.<property name>": {
            "type": "<property type>",
            "value": "<property value>"
        },
        ...
    }
}
```

Once a config file has been created, the environment variable `TILE_CONFIG_PATH` locates the file.

For example, if the config file is at */home/me/workspace/my-tile.config*:

```bash
$ export TILE_CONFIG_PATH=/home/me/workspace/my-tile.config
```

### 4. Get a Pivnet token

If any pre-requisite resources need to be installed for the test to succeed (stemcells needs to be installed for instance) they will be downloaded from Pivnet and installed. A token is required for download.

[How to find your Pivnet token](https://network.pivotal.io/docs/api/#how-to-authenticate)

Once the Pivnet token as been acquired, the environment variable `PIVNET_TOKEN` must contain its value.

For example, if the Pivnet token is *a62fd1q7b41a44e19ba05112a13754z2-r*:

```bash
$ export PIVNET_TOKEN=a62fd1q7b41a44e19ba05112a13754z2-r
```

### 5. OpsManager credentials

Finally, an instances of PAS is needed to run the test. Developers may configure their own, or a Pivotal PE team member may provide access to one.

Three pieces of information are needed to identify and authenticate with the PAS environment. The URL of the OpsManager instance, a user name and a password.

For example, if the URL is *https://pcf.hawthorne.cf-app.com*, user name is *pivotalcf*, and password is *o10q4qqfjdc523uv*:

```bash
$ export OM_USERNAME=https://pcf.hawthorne.cf-app.com
$ export OM_PASSWORD=pivotalcf
$ export OM_TARGET=o10q4qqfjdc523uv
```

#### Note on skipping SSL Validation

It is very likely that the OpsManager instance uses a self signed SSL certificate. This will result in authentication failures during the test. To avoid these failures, `OM_SKIP_SSL_VALIDATION` should be set to true to skip the SSL validation steps.

```bash
$ export OM_SKIP_SSL_VALIDATION=true
```

### 6 Now run the test!

Once the steps above have been completed, its time to run the test.

[Docker](https://www.docker.com/) is required to execute the test.

```bash
$ docker run \
  -e OM_USERNAME \
  -e OM_PASSWORD \
  -e OM_TARGET \
  -e OM_SKIP_SSL_VALIDATION \
  -e PIVNET_TOKEN \
  -e TILE_NAME=$(basename "${TILE_PATH}") \
  -e TILE_CONFIG=$(basename "${TILE_CONFIG_PATH}") \
  -v $(dirname "${TILE_PATH}"):/input/tile \
  -v $(dirname "${TILE_CONFIG_PATH}"):/input/tile-config \
  cfplatformeng/install-uninstall-test-image
```

This will fetch the test image and begin the test execution. Depending on the complexity of the integration, this could take tens of minutes to an hour or two.

## Advanced Topics

### Makefile

There are some make targets to aid running and troubleshooting tests. There are also make targets to test the tools.

### Requirements

Using the Makefile requires a few tools:

- [BATS](https://github.com/bats-core/bats-core) to test shell scripts
- [shellcheck](https://github.com/koalaman/shellcheck) to lint shell scripts

### Running the test

To use the Makefile to run the test (this requires the same environment variables as above):

```bash
$ make run
```

### Development

The test script is inside of `run.sh`.  Changes there should be tested and reflected in the `run.bats` test file.

This test also utilizes several of the [tool scripts](https://github.com/cf-platform-eng/isv-ci-toolkit/tree/master/tools).

Run the unit tests with:

```bash
$ make test
```

To extend the test to add new functionality, consider creating a new docker image that inherits from this one, or copy this one and make your modifications in the copy.

### Troubleshooting

If you want to debug the execution, you can get a shell in the test container before the test executes by using:

```bash
$ make shell
```

Then, source the test functions and now you can run each test step in sequence:

```bash
root@5cd0c73b7329:/test# source test_functions.sh
root@5cd0c73b7329:/test# config_file_check
section-start: 'config file check' MRL:{"type":"section-start","name":"config file check","time":"2019-09-27T15:02:10.1187724Z"}
The config file appears to be valid
section-end: 'config file check' result: 0 MRL:{"type":"section-end","name":"config file check","time":"2019-09-27T15:02:10.1397465Z"}
root@5cd0c73b7329:/test# install_tile
...
```

## Reference

### Environment Variables

The following environment variables are necessary to run the process:

- `OM_TARGET` - OpsManager URL
- `OM_USERNAME` - OpsManager username
- `OM_PASSWORD` - OpsManager password
- `TILE_PATH` - Full path to integration
- `TILE_CONFIG_PATH` - Full path to configuration file
- `PIVNET_TOKEN` - Authentication token for Pivotal Network ([how to find](https://network.pivotal.io/docs/api/#how-to-authenticate)). Used in case the test needs to download any missing stemcells.

The following environment variables may be used, but not required:

- `OM_SKIP_SSL_VALIDATION` - set to `true` if your OpsManager is using self-signed SSL certificates
- `USE_FULL_DEPLOY` - if set to `true`, deploy all staged products. Defaults to `false`, which only deploys the integration under test.

NOTE: Using `USE_FULL_DEPLOY` will result in a slower test runtime, but may catch incompatibilities with other integrations.

### Configuration file

The configuration file may be json or yaml.

[Tips for building a valid config file](https://github.com/cf-platform-eng/isv-ci-toolkit/blob/master/docs/creating-tile-configs.md)

The configuration file should include the product-properties section:

YAML example:

```yaml
product-properties:
  ".properties.apply_open_security_group":
    value: false
    type: boolean
  ".properties.allow_paid_service_plans":
    value: false
    type: boolean
  ".properties.org":
    value: test-tile-org
    type: string
  ".properties.space":
    value: test-tile-space
    type: string
```

JSON example:

```json
{
    "product-properties": {
        ".properties.space": {
            "type": "string",
            "value": "test-tile-space"
        },
        ".properties.allow_paid_service_plans": {
            "type": "boolean",
            "value": false
        },
        ".properties.apply_open_security_group": {
            "type": "boolean",
            "value": false
        },
        ".properties.org": {
            "type": "string",
            "value": "test-tile-org"
        }
    }
}
```

### Substitution strings

The following substitution strings may be used to reference properties that might be specific to the test environment

- `{az}` will be replaced with the name of an availability zone in the environment.
- `{disk_type}` will be replaced with the name of a disk type in the environment.
- `{vm_type}` will be replaced with the name of a vm type in the environment.
