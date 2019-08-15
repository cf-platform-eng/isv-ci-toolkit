# Install, configure, apply changes, uninstall a PAS tile

This test will upload, install, stage, configure and uninstall a tile on a Pivotal Cloud Foundry foundation. At any point, if the step fails, the test will stop.

## Setup

Docker is required to run this test.  The test itself is a docker image that runs the test commands against a pre-configured OpsManager.

The following environment variables are necessary to run the process:

- OM_TARGET - url for opsman (ex: `https://pcf.vividlimegreen.cf-app.com`)
- OM_USERNAME - opsman username
- OM_PASSWORD - opsman password
- TILE_PATH - path to tile
- TILE_CONFIG_PATH - path to tile config file
- PIVNET_TOKEN - token to download any missing stemcells

The following environment variables are used, but not necessary:

- OM_SKIP_SSL_VALIDATION - if your opsman is using self-signed certs
- USE_FULL_DEPLOY - if set to `true`, deploy all staged products

NOTE: Using `USE_FULL_DEPLOY` will result in a slower test runtime, but will catch product incompatibilities.

## Config file

The configuration file should include the product-properties section:

YAML:

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

JSON:

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

The following substitution strings may be used to reference properties that may vary between test environments

- `{az}` will be replaced with the name of an availability zone in the environment.
- `{disk_type}` will be replaced with the name of a disk type in the environment.
- `{vm_type}` will be replaced with the name of a vm type in the environment.

## Running the test

The test can take 1+ hours to run. You can invoke it with the Makefile or directly through Docker:

### Use with Makefile

Running the test with the Makefile will build locally, check for the required variables, and execute.

To run test after setup and config:

```bash
make run
```

### Use the Docker image directly

Running the Docker image directly is useful if you want to run the test inside of a CI system where the image is not built locally.

```bash
export OM_USERNAME=...
export OM_PASSWORD=...
export OM_TARGET=...
export OM_SKIP_SSL_VALIDATION=true|false
export PIVNET_TOKEN=...
export TILE_PATH=/path/to/my-tile.pivotal
export TILE_CONFIG_PATH=/path/to/tile/config.yml
docker run \
  -e OM_USERNAME \
  -e OM_PASSWORD \
  -e OM_TARGET \
  -e OM_SKIP_SSL_VALIDATION \
  -e PIVNET_TOKEN \
  -e TILE_NAME=$(basename "${TILE_PATH}") \
  -e TILE_CONFIG=$(basename "${TILE_CONFIG_PATH}") \
  -v $(dirname "${TILE_PATH}"):/tile \
  -v $(dirname "${TILE_CONFIG_PATH}"):/tile-config \
  cfplatformeng/install-uninstall-test-image
```

### Output

The output of this test is the logs of the `om` cli commands

## Development

The test script is inside of `scripts/pas-test.sh`.  Changes there should be tested and reflected in the `pas-test.bats` test file.

This test also utilizes several of the [tool scripts](https://github.com/cf-platform-eng/isv-ci-toolkit/tree/master/tools).

Run the unit tests with:

```bash
make test
```

To extend the test to add new functionality, consider creating a new docker image that inherits from this one, or copy this one and make your modifications in the copy.

## Troubleshooting

If you want to debug the execution, you can get a shell in the test container before the test executes by using:

```bash
make shell
```

Any other issues, feel free to reach out to the ISV-CI team.
