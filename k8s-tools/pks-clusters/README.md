# PKS Cluster Tools

Tools to create and delete PKS clusters.

## Configuration

Environment variables, etc necessary to configure and capture cluster operations and results.

### Input - GCP Authentication

A GCP service account key is required. The json string for the account key should be provided in the GCP_CREDS environment variable.

### Input - PKS Authentication

Three environment variables are necessary to identify and authenticate the PKS instance on which to create the cluster.
- PKS_API the PKS api url, including port (example: https://api.pks.dalycity.cf-app.com:9021)
- PKS_USER_NAME account user name to authenticate to PKS
- PKS_PASSWORD accout password for user

### Output - kubectl config

Once a cluster is created, the necessary *kubectl* config file will be available in the container at */pci/k8s/config*. If it is necessary to access the cluster in subsequent steps, a non-volatile volume should be mounted at */pci*. This could be a host directory, or a docker volume mounted across docker run steps.

To configure *kubectl* with the context for the new cluster when running tests:
```/bin/bash
export KUBECONFIG=/pci/k8s/config
kubectl config use-context <clustername>
```

#### To create a cluster
```
GCP_CREDS=<service account key json string>
PKS_API=<pks api URL>
PKS_USER_NAME=<pks user name>
PKS_PASSWORD=<pks password>
create-cluster.sh <cluster name> <cluster plan>
```

The local directory *pci/k8s/config* will have the resulting kubectl config file that can be used to target *kubectl* at the new cluster.
```
KUBECONFIG=`pwd`/pci/k8s/config kubectl config use-context <cluster name>
```
#### To delete a cluster
```
GCP_CREDS=<service account key json>
PKS_API=<pks api URL>
PKS_USER_NAME=<pks user name>
PKS_PASSWORD=<pks password>
delete-cluster.sh <cluster name>
```