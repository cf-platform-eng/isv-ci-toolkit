# GKE Cluster Tools

Tools to create and delete GKE clusters.

## Configuration

Environment variables, etc necessary to configure and capture cluster operations and results.

### Input - Authentication

Authenticating with Google Cloud Services is done with a service account key. This is a json document, and the location of the file containing the key must be available in the GCP_CREDS_FILE environment variable.

This account key is used by to tool to authenticate to GCS:
```
gcloud auth activate-service-account --key-file=/tmp/certs/svc_account.json
```

### Output - kubectl config

Once a cluster is created, the necessary *kubectl* config file will be available in the container at */pci/k8s/config*. If it is necessary to access the cluster in subsequent steps, a non-volatile volume should be mounted at */pci*. This could be a host directory, or a docker volume mounted across docker run steps.

To configure *kubectl* with the context for the new cluster when running tests:
```/bin/bash
export KUBECONFIG=/pci/k8s/config
kubectl config use-context <clustername>
```

### Usage

#### To create a cluster
```
GCP_CREDS_FILE=<path to service account key .json> create-cluster.sh <cluster name>
```

The local directory *pci/k8s/config* will have the resulting kubectl config file that can be used to target *kubectl* at the new cluster.
```
KUBECONFIG=`pwd`/pci/k8s/config kubectl config use-context <cluster name>
```
#### To delete a cluster
```
GCP_CREDS_FILE=<path to service account key .json> delete-cluster.sh <cluster name>
```
