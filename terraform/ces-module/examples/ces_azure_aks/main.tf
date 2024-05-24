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

  tags = {
    environment = "CES"
  }
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

  tags = {
    environment = "CES"
  }
}

module "ces" {
  source = "../../"

  # Configure the access to the Kubernetes-Cluster
  kubernetes_host                   = azurerm_kubernetes_cluster.default.kube_config[0].host
  kubernetes_client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].client_certificate)
  kubernetes_client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].client_key)
  kubernetes_cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].cluster_ca_certificate)

  # Configure CES installation options
  setup_chart_version   = var.setup_chart_version
  setup_chart_namespace = var.setup_chart_namespace
  ces_fqdn              = var.ces_fqdn
  ces_admin_password    = var.ces_admin_password
  additional_dogus      = var.additional_dogus
  resource_patches_file = var.resource_patches_file

  # Configure access for the registries. Passwords need to be base64-encoded.
  image_registry_url      = var.image_registry_url
  image_registry_username = var.image_registry_username
  image_registry_password = var.image_registry_password

  dogu_registry_username = var.dogu_registry_username
  dogu_registry_password = var.dogu_registry_password
  dogu_registry_endpoint = var.dogu_registry_endpoint

  helm_registry_host       = var.helm_registry_host
  helm_registry_schema     = var.helm_registry_schema
  helm_registry_plain_http = var.helm_registry_plain_http
  helm_registry_username   = var.helm_registry_username
  helm_registry_password   = var.helm_registry_password
}