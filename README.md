# ISV CI Toolkit

This repo contains curated content for Pivotal Partners to use when testing their integrations with Pivotal Cloud Foundry.

Some essential reading:

* [The ISV CI design guide](./docs/design-guide.md)
* [The Getting Started guide](./docs/getting-started-guide.md)

## Tests

The `tests` directory contains docker images that execute a test.

The most basic test that can be run is [installing, configuring and then uninstalling](./tests/install-uninstall-pas-tile/README.md) a tile.

## Tasks

The `tasks` directory contain docker images that execute a function against an environment. They are often used for doing further configuration for environments before executing a test image.
