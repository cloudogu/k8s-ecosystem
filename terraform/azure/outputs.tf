output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}

output "host" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.default.kube_config.0.host
}

output "client_key" {
  sensitive = true
  value = azurerm_kubernetes_cluster.default.kube_config.0.client_key
}

output "client_certificate" {
  sensitive = true
  value = azurerm_kubernetes_cluster.default.kube_config.0.client_certificate
}

output "kube_config" {
  sensitive = true
  value = azurerm_kubernetes_cluster.default.kube_config_raw
}

output "cluster_username" {
  sensitive = true
  value = azurerm_kubernetes_cluster.default.kube_config.0.username
}

output "cluster_password" {
  sensitive = true
  value = azurerm_kubernetes_cluster.default.kube_config.0.password
}

#output "yaml" {
#  sensitive = true
#  value = kubectl_manifest.setup_resources_apply.yaml_body
#}