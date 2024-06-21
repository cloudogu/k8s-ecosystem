# Kubelet-Private-Registry-Config

Creates a secret with the kubelet-config for private registries (https://kubernetes.io/docs/concepts/containers/images/#config-json) 
This config is copied to each node by a daemon-set wich mounts the secret.

## Usage

Import this module in your terraform template like:

```terraform
module "kubelet_private_registry" {
  depends_on = [module.google_gke] # Change this according your used cloud provider module
  source = "../../kubelet-private-registry"

  image_registry_url      = var.image_registry_url
  image_registry_username = var.image_registry_username
  image_registry_password = var.image_registry_password
}
```