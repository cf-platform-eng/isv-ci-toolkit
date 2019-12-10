# ksm-install

Given
* PAS installed on Ops Manager
* PKS installed on Ops Manager (can be different OM)
* A Google Cloud key with
    * Cloud Storage Admin
    * IAM admin
* A PKS cluster configuration (could be our own custom config schema OR the PKS schema for a plan)

This task:
  * creates a GCS Bucket
  * creates a SAK that can list, read and create on the bucket
  * configures and updates the plan 1 cluster on PKS
  * stages, configures and installs KSM on the PAS
    * configured with the cluster credentials and the Storage bucket SAK


# TODO

* Probably should call this `install-ksm` to be consistent with other tools