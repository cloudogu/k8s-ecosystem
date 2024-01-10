terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.65.0"
    }
  }

  required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
}

locals {
  azure_client_id = "MY Client ID"
  azure_client_secret = "CLIENT_SECRET"
  aks_cluster_name = "test-terraform-module"
}

resource "azurerm_resource_group" "default" {
  name     = "${local.aks_cluster_name}-rg"
  location = "West Europe"

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
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = local.azure_client_id
    client_secret = local.azure_client_secret
  }

  role_based_access_control_enabled  = true

  tags = {
    environment = "CES"
  }
}

module "ces" {
  source = "../../"
  kubernetes_host = azurerm_kubernetes_cluster.default.kube_config.0.host
  kubernetes_client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  kubernetes_client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  kubernetes_cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  ces_fqdn = "ces-aks.local"
  image_registry_url = "registry.cloudogu.com"
  image_registry_username = "username"
  image_registry_password = "password"
  image_registry_email = "test@test.de"
  dogu_registry_username = "username"
  dogu_registry_password = "password"
  dogu_registry_endpoint = "https://dogu.cloudogu.com/api/v2/dogus"
  helm_registry_host="registry.cloudogu.com"
  helm_registry_schema="oci"
  helm_registry_plain_http=false
  helm_registry_username = "username"
  helm_registry_password = "password"
  setup_chart_version = "0.20.2"
  setup_chart_namespace = "k8s"
  ces_admin_password="test123"
  additional_dogus = ["official/jenkins", "official/scm"]
}