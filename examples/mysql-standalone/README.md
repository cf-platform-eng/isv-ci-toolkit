# MYSQL Standalone Bazaar deployment test

* Not on demand 
* No create-service
* Requires only PKS.

Used to establish the 'Test µplatform'


## Setup

login to pks

```bash
    export CLUSTER_NAME=<cluster_name> # this is used by the makefile later, not just get-credentials
    pks login -a https://api.pks.whatever.com:9021 -u <username> -p <password> -k
    pks get-credentials ${CLUSTER_NAME}
    
```

## Debug process

TODO - explain how we set up and run interactive debugging.