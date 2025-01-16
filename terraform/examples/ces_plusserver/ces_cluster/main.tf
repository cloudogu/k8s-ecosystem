terraform {
  required_version = ">= 0.13"ä
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2"
    }
  }

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}


module "plusserver" {
  source             = "../../../plusserver"
  kube_config_path   = var.gardener_kube_config_path
}


module "ces" {
  depends_on = [module.plusserver]
  source     = "../../../ces-module"

  # Configure CES installation options
  setup_chart_version          = var.setup_chart_version
  setup_chart_namespace        = var.setup_chart_namespace
  ces_fqdn                     = var.ces_fqdn
  ces_admin_username           = var.ces_admin_username
  ces_admin_password           = var.ces_admin_password
  dogus                        = var.dogus
  resource_patches             = file(var.resource_patches_file)
  component_operator_chart     = var.component_operator_chart
  component_operator_crd_chart = var.component_operator_crd_chart
  components                   = var.components

  # Configure access for the registries. Passwords need to be base64-encoded.
  container_registry_secrets = var.container_registry_secrets
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password
  dogu_registry_endpoint     = var.dogu_registry_endpoint
  dogu_registry_url_schema   = var.dogu_registry_url_schema

  helm_registry_host         = var.helm_registry_host
  helm_registry_schema       = var.helm_registry_schema
  helm_registry_plain_http   = var.helm_registry_plain_http
  helm_registry_insecure_tls = var.helm_registry_insecure_tls
  helm_registry_username     = var.helm_registry_username
  helm_registry_password     = var.helm_registry_password
}
