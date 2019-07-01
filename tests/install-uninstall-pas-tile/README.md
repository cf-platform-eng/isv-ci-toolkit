# Install, configure, apply changes, uninstall a PAS tile

Takes a PAS tile and some config and installs them on a foundation. Uploads the tile, stages the tile, configs the tile, applies changes, unstages the tile and then deletes it.

## Setup

Requires docker. The test runner is packaged up in a container.

The following environment variables are necessary to run the process:

- OM_TARGET - url for opsman (ex: `https://pcf.vividlimegreen.cf-app.com`)
- OM_USERNAME - opsman username
- OM_PASSWORD - opsman password
- OM_SKIP_SSL_VALIDATION - if your opsman is using self-signed certs
- TILE_PATH - path to tile
- TILE_CONFIG_PATH - path to tile config file
- PIVNET_TOKEN - token to download any needed stemcells

## Config

Config should include only the product-properties section:

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
```

## Use

To run test after setup and config:

```bash
make run
```

To get a shell in the test container:

```bash
make shell
```
