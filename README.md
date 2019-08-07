# ISV CI Toolkit

This repo contains curated content for Pivotal Partners to use when testing their integrations with Pivotal Cloud Foundry.

Some essential reading:
  * [The ISV CI design guide](./docs/design-guide.md)
  * [The Getting Started guide](./docs/getting-started-guide.md)


## Tests

The `tests` directory contains docker images that execute a test.

## Tasks

The `tasks` directory contain docker images that execute a function against an environment. They are often used for doing further configuration for environments before executing a test image.

## Base Image

The `base-image` directory contains a docker image that is a useful base image. It is not public yet, because it contains binaries that are not yet licensed for public distribution

## PAS Image

The `pas-image` directory contains a docker image that contains useful binaries for executing tests and tasks. It will be replaced by the base image when the licensing challenges have been addressed.
