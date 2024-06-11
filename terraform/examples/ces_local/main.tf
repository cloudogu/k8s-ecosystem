terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2"
    }
  }

  required_version = ">= 1.7.0"
}

provider kubernetes {
  config_path = var.local_kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = var.local_kube_config_path
  }

  registry {
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

module "ces" {
  source = "../../ces-module"

  # Configure CES installation options
  setup_chart_version   = var.setup_chart_version
  setup_chart_namespace = var.setup_chart_namespace
  ces_fqdn              = var.ces_fqdn
  ces_admin_username    = var.ces_admin_username
  ces_admin_password    = var.ces_admin_password
  additional_dogus      = var.additional_dogus
  additional_components = var.additional_components
  resource_patches_file = var.resource_patches_file

  # Configure access for the registries. Passwords need to be base64-encoded.
  image_registry_url      = var.image_registry_url
  image_registry_username = var.image_registry_username
  image_registry_password = var.image_registry_password

  dogu_registry_username   = var.dogu_registry_username
  dogu_registry_password   = var.dogu_registry_password
  dogu_registry_endpoint   = var.dogu_registry_endpoint
  dogu_registry_url_schema = var.dogu_registry_url_schema

  helm_registry_host         = var.helm_registry_host
  helm_registry_schema       = var.helm_registry_schema
  helm_registry_plain_http   = var.helm_registry_plain_http
  helm_registry_insecure_tls = var.helm_registry_insecure_tls
  helm_registry_username     = var.helm_registry_username
  helm_registry_password     = var.helm_registry_password
}