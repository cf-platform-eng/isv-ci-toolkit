# K8S Tools
Collection of tools for various K8S distros.

Includes tools to create and destroy clusters in PKS and GKE.

## Basics
These tools can be used to create and destry clusters. Cluster creation should result in kubectl config file that can be used to change *kubectl* context to the created cluster.

The config file should be written into the file */pci/k8s/config*. This path should be mounted into any test images that require access to the cluster so that it can be shared across container invocations.

To configure pksctl to target the cluster:
```/bin/bash
export KUBECONFIG=/pci/k8s/config
kubectl config use-context <clustername>
```