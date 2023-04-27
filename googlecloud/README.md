# CES-Multinode on a GKE-Cluster

## TODO

- install longhorn
  - without podsecuritypolicies
- create namespace
- install setup
- Done

## Notes und Mistakes 

- Get Credentials:

`gcloud container clusters get-credentials ces-multinode`

- Change nodepool size:

`gcloud container clusters resize ces-multinode --num-nodes=0`

- CES-Role does not have permissions to handle specific resources:
  - Clusterroles
  - Clusterrolebinding
  - Roles
  - ...

