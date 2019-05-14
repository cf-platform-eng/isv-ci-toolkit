# MYSQL Bazaar deployment test with cluster creation

* Examples for both on demand pks and gke clusters

Used to establish the cluster configuration propagation in the 'Test µplatform'


## Setup

The K8S_CLUSTER environment variable must contain the name of the cluster to target for the test run.

Set IaaS access environment variables:

### For PKS
```bash
GCP_CREDS=<service account key json string>
PKS_API=<pks api URL>
PKS_USER_NAME=<pks user name>
PKS_PASSWORD=<pks password>
```

### For GKE
```bash
GCP_CREDS_FILE=<path to file containing service account key json>
```

## Makefile
The Makefile has the following useful targets:
- *build*: builds the test container
- *run*: runs the test container
- *run-pks*: create a PKS cluster, run the test against the cluster and delete the cluster
- *run-gke*: create a GKE cluster, run the test against the cluster and delete the cluster
- *gcb-pks*: run the test flow in google cloud build - create a pks cluster, run the test, delete the cluster

## Dockerfile
The dockerfile that creates the test image copies the contents the *./test* directory into the image at */test* and sets the default command:
```
CMD ["/bin/bash", "-c", "cd /test && source commands.sh && run"]
```
The docker file also copies the script *configkube* into */test* that *command.sh* calls to configure *kubectl* to target the proper cluster ($K8S_CLUSTER)
