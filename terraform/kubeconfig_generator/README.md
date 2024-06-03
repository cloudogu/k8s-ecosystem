# Kubeconfig Terraform module

This module can generate a kubeconfig file for accessing a kubernetes cluster.

## setup

For Gcloud you can use this:
```terraform
module "kubeconfig_generator" {
  source                 = "../../kubeconfig_generator"
  cluster_name           = var.cluster_name
  access_token           = module.google_gke.access_token
  cluster_ca_certificate = module.google_gke.ca_certificate
  cluster_endpoint       = "https://${module.google_gke.endpoint}"

  kubeconfig_path = "kubeconfig"
}
```

Be aware that this way a short-lived access token is used. 

## integration in your own code