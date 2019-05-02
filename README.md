# ISV CI Toolkit

This repo contains curated content for Pivotal Partners to use when testing their contributions to Pivotal's One Platform.

## Dev
Requirements:
- docker
- pivnet cli (brew install pivotal/tap/pivnet-cli) 
  - must be logged into pivnet (pivnet login --api-token=[token])
- lastpass cli

Environment and secrets setup with scripts/set-env.sh
```
. ./scripts/set-env.sh
```

# PAS

The PAS docker image is designed as a basis for test images that extend the Pivotal PAS offering.
