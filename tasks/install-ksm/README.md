# install-ksm

Given

* PAS installed on Ops Manager
* PKS installed on Ops Manager (can be different OM)
* A Google Cloud key with
  * Compute Viewer
  * Security Admin
  * Create Service Accounts
  * Storage HMAC Key Admin
  * Delete Service Accounts
  * Storage Admin
* A PKS cluster configuration (could be our own custom config schema OR the PKS schema for a plan)

This task:

* creates a GCS Bucket
* creates a SAK that can list, read and create on the bucket
* configures and updates the plan 1 cluster on PKS
* stages, configures and installs KSM on the PAS
  * configured with the cluster credentials and the Storage bucket SAK

## TODO

* create s3 compatible keys
* use the service account in the KSM install
  