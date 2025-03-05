# Plusserver PSKE module

This module creates kubernetes cluster in Plusserver.
It technically creates a shoot resource in a given gardener cluster.
The reconciliation in the gardener cluster creates a controlplane in a seed cluster
and a separate shoot cluster for workloads.

> Info: The seed cluster is not accessible for the user.

## Requirements

To create a cluster you need to configure the garden namespace, secret binding, and project id.
See `variables.tf` for more details.

In your terraform module you have to configure the `gavinbunney/kubectl` provider with your gardener credentials.
All information is available in your [PSKE Dashboard](https://dashboard.prod.gardener.get-cloud.io/).

## Generate kubeconfig for shoot cluster

```bash
export NAMESPACE=garden-my-namespace
export SHOOT_NAME=my-shoot
export KUBECONFIG=<kubeconfig for garden cluster>  # can be set using "gardenctl target --garden <landscape>"
kubectl create \
-f <(printf '{"spec":{"expirationSeconds":600}}') \
--raw /apis/core.gardener.cloud/v1beta1/namespaces/${NAMESPACE}/shoots/${SHOOT_NAME}/adminkubeconfig | \
jq -r ".status.kubeconfig" | \
base64 -d > shootconfig.yaml
```
