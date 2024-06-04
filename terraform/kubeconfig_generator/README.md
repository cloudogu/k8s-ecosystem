# Kubeconfig Terraform module

This module can generate a kubeconfig file for accessing a kubernetes cluster.

## setup with GCloud

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

Be aware that this way a short-lived access token is used. The token will be updated at every further `terraform apply`.

## setup with Azure

Notice that azure has its own way to get the kubeconfig via `azurerm_kubernetes_cluster.aks.kube_config_raw`.
You can write it to a file with:
```terraform
resource "local_sensitive_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "my/.kube/config"
}
```

## get kubeconfig

You can retrieve the kubeconfig as a string with the `kubeconfig_content` output variable. 
If you want it as a file, specify the `kubeconfig_path` variable. If you don't set this variable no kubeconfig will be written.