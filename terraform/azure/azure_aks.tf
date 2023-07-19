provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${var.aks_cluster_name}-rg"
  location = "West Europe"

  tags = {
    environment = "CES"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.aks_cluster_name}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${var.aks_cluster_name}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = var.aks_node_count
    vm_size         = var.aks_vm_size
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.azure_appId
    client_secret = var.azure_password
  }

  role_based_access_control_enabled  = true

  tags = {
    environment = "CES"
  }
}