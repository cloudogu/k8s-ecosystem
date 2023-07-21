output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}

output "azure_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "azure_jenkins_agent_subnet_name" {
  value = azurerm_subnet.jenkins_agents_subnet.name
}

output "azure_jenkins_storage_account_name" {
  value = azurerm_storage_account.jenkins_agents_storage.name
}

output "get_credentials" {
  value = format("az aks get-credentials --resource-group %s --name %s", azurerm_resource_group.default.name, azurerm_kubernetes_cluster.default.name)
}