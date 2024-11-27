terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.105.0"
    }
  }

  required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
}

locals {
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  aks_cluster_name    = var.aks_cluster_name
}

resource "azurerm_resource_group" "default" {
  name     = "${local.aks_cluster_name}-rg"
  location = var.azure_resource_group_location

  tags = var.tags
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${local.aks_cluster_name}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${local.aks_cluster_name}-k8s"

  default_node_pool {
    name            = var.node_pool_name
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = var.os_disk_size_gb
  }

  service_principal {
    client_id     = local.azure_client_id
    client_secret = local.azure_client_secret
  }

  role_based_access_control_enabled = true

  tags = var.tags
}