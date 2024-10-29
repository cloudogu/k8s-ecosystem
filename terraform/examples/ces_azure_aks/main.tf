terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.105.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2"
    }
  }

  required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
}

locals {
  az_module_host                   = module.azure.kubernetes_host
  az_module_client_certificate     = base64decode(module.azure.kubernetes_client_certificate)
  az_module_client_key             = base64decode(module.azure.kubernetes_client_key)
  az_module_cluster_ca_certificate = base64decode(module.azure.kubernetes_cluster_ca_certificate)
}

provider "kubernetes" {
  host                   = local.az_module_host
  client_certificate     = local.az_module_client_certificate
  client_key             = local.az_module_client_key
  cluster_ca_certificate = local.az_module_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = local.az_module_host
    client_certificate     = local.az_module_client_certificate
    client_key             = local.az_module_client_key
    cluster_ca_certificate = local.az_module_cluster_ca_certificate
  }

  registry {
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

module "azure" {
  source                        = "../../azure_aks"
  azure_client_id               = var.azure_client_id
  azure_client_secret           = var.azure_client_secret
  azure_resource_group_location = var.azure_resource_group_location
}

#module "kubelet_private_registry" {
#  depends_on = [module.azure]
#  source     = "../../kubelet-private-registry"
#
#  private_registries = [
#    {
#      "url"      = var.image_registry_url
#      "username" = var.image_registry_username
#      "password" = var.image_registry_password
#    }
#  ]
#}

module "ces" {
  depends_on = [module.azure]
  source     = "../../ces-module"

  # Configure CES installation options
  setup_chart_version   = var.setup_chart_version
  setup_chart_namespace = var.setup_chart_namespace
  ces_fqdn              = var.ces_fqdn
  ces_admin_password    = var.ces_admin_password
  dogus                 = var.dogus
  resource_patches      = file(var.resource_patches_file)

  # Configure access for the registries. Passwords need to be base64-encoded.
  container_registry_secrets = var.container_registry_secrets
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password
  dogu_registry_endpoint     = var.dogu_registry_endpoint

  helm_registry_host       = var.helm_registry_host
  helm_registry_schema     = var.helm_registry_schema
  helm_registry_plain_http = var.helm_registry_plain_http
  helm_registry_username   = var.helm_registry_username
  helm_registry_password   = var.helm_registry_password
}