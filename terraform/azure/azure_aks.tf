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

resource "azurerm_virtual_network" "vnet" {
  name                        = "${var.aks_cluster_name}-vnet"
  location                    = azurerm_resource_group.default.location
  resource_group_name         = azurerm_resource_group.default.name
  address_space               = ["10.1.0.0/16"]
  tags = {
    environment = "CES"
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                        = "aks_subnet"
  resource_group_name         = azurerm_resource_group.default.name
  virtual_network_name        = azurerm_virtual_network.vnet.name
  address_prefixes            = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "jenkins_agents_subnet" {
  name                        = "jenkins_agents_subnet"
  resource_group_name         = azurerm_resource_group.default.name
  virtual_network_name        = azurerm_virtual_network.vnet.name
  address_prefixes            = ["10.1.2.0/24"]
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
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
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