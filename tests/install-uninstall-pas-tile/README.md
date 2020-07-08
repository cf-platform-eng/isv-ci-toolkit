# Test Install, configure, apply changes, and uninstall a PAS tile

This test will upload, install, stage, configure and uninstall a tile on a Pivotal Cloud Foundry foundation. If at any point a step fails, the test will stop.

## Running the test

Here is what you need to run the test:

### 1. Locate the the .pivotal integration that will be tested

Locates the .pivotal file that contains the integration to test, and note the absolute path to that file.

### 2. Create a configuration to test the integration against

The test will configure the integration with the provided settings and run apply changes to make sure the integration configures and installs. It is up to the integration developer to create a configuration appropriate for their integration.

[Tips for building a valid config file](https://github.com/cf-platform-eng/isv-ci-toolkit/blob/main/docs/creating-tile-configs.md)

A configuration file will look like this:

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

### 3. Get a Pivnet token

If any pre-requisite resources need to be installed for the test to succeed (e.g. missing stemcells) they will be downloaded from [PivNet](https://network.pivotal.io) and installed. A PivNet token is required for download.

[How to find your Pivnet token](https://network.pivotal.io/docs/api/#how-to-authenticate)

Once the PivNet token as been acquired, set the environment variable `PIVNET_TOKEN` with its value.

For example, if the Pivnet token is *a62fd1q7b41a44e19ba05112a13754z2-r*:

```bash
export PIVNET_TOKEN=a62fd1q7b41a44e19ba05112a13754z2-r
```

### 4. OpsManager credentials

Finally, an instance of the Pivotal Platform is needed to run the test. You may configure your own, or a Pivotal Platform Engineering team member may provide access to one.

Three pieces of information are needed to identify and authenticate with the platform. The URL of the OpsManager instance, a user name and a password.

For example, if the URL is *https://pcf.hawthorne.cf-app.com*, user name is *pivotalcf*, and password is *o10q4qqfjdc523uv*, then set these environment variables:

```bash
export OM_USERNAME=pivotalcf
export OM_PASSWORD=o10q4qqfjdc523uv
export OM_TARGET=https://pcf.hawthorne.cf-app.com
```

#### Note on skipping SSL Validation

It is very likely that the OpsManager instance uses a self signed SSL certificate. This will result in authentication failures during the test. To avoid these failures, `OM_SKIP_SSL_VALIDATION` should be set to true to skip the SSL validation steps.

```bash
export OM_SKIP_SSL_VALIDATION=true
```

### 5 Now run the test!

Run the test with the docker image:

```bash
docker run \
  -e OM_USERNAME \
  -e OM_PASSWORD \
  -e OM_TARGET \
  -e OM_SKIP_SSL_VALIDATION \
  -e PIVNET_TOKEN \
  -v /full/path/to/your/tile.pivotal:/input/tile.pivotal \
  -v /full/path/to/your/config-file.json:/input/config.json \
  cfplatformeng/install-uninstall-test-image
```

This will fetch the test image and begin the test execution. Depending on the complexity of the integration, this could take several minutes to a few hours.

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

### Configuration file

The configuration file may be json or yaml.

[Tips for building a valid config file](https://github.com/cf-platform-eng/isv-ci-toolkit/blob/main/docs/creating-tile-configs.md)

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
