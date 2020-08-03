# Deploy Tile

Running this task will take a tile (or download one from Tanzu Network) and deploy it to a Tanzu OpsManager

## Inputs

This task requires communication with the OpsManager via the `om` tool, a tile, and a configuration file for that tile. Alternatively, you can supply environment variables that allow the task to download the tile from the Tanzu Network:

* `OM_TARGET` environment variable
* `OM_USERNAME` environment variable
* `OM_PASSWORD` environment variable
* `OM_SKIP_SSL_VALIDATION` environment variable
* Either of:
  * A tile file (*.pivotal)
        OR
  * `PIVNET_TOKEN` environment variable
  * `TILE_SLUG` environment variable
  * `TILE_VERSION` environment variable
* config.json configuration file
