# Install, configure, apply changes, uninstall a PAS tile

Takes a PAS tile and some config and installs them on a foundation. Uploads the tile, stages the tile, configs the tile, applies changes, unstages the tile and then deletes it.

## Setup

The following environment variables are necessary to run the process:
- OM_TARGET - url for opsman (ex: https://pcf.vividlimegreen.cf-app.com)
- OM_USERNAME - opsman username
- OM_PASSWORD - opsman password
- TILE_PATH - path to tile
- TILE_CONFIG_PATH - path to tile config yaml file
- PIVNET_TOKEN - token to download any needed stemcells

## Config

The config yaml file should include only the product-properties section - example:

```
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
