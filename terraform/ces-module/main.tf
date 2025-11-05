# The local Closure converts input Parameter to usable template parameters
locals {
  // enforce version
  component_operator_crd_chart = length(split(":", var.component_operator_crd_chart)) == 2 ? var.component_operator_crd_chart : var.component_operator_crd_chart + ":1.10.1"
  component_operator_image = length(split(":", var.component_operator_image)) == 2 ? var.component_operator_image : var.component_operator_image + ":latest"
}


module "ces-preparation" {
  source                 = "./ces-preparations"

  docker_registry_email = var.docker_registry_email
  docker_registry_host = var.docker_registry_host
  docker_registry_password = var.docker_registry_password
  docker_registry_username = var.docker_registry_username

  dogu_registry_password = var.dogu_registry_password
  dogu_registry_username = var.dogu_registry_username

  helm_registry_password = var.helm_registry_password
  helm_registry_username = var.helm_registry_username

  component_operator_crd_chart = local.component_operator_crd_chart

  ces_namespace = var.ces_namespace
}

module "ces-core" {
  source = "./ces-core"
  depends_on = [module.ces-preparation]

  helm_registry_host = var.helm_registry_host
  helm_registry_schema = var.helm_registry_schema

  ces_namespace = var.ces_namespace

  component_operator_image = local.component_operator_image
  components = var.components

  default_dogu = var.default_dogu

  ecosystem_core_chart_namespace = var.ecosystem_core_chart_namespace
  ecosystem_core_chart_version = var.ecosystem_core_chart_version
  ecosystem_core_timeout = var.ecosystem_core_timeout

  externalIP = var.externalIP

  ces_admin_password = var.ces_admin_password

  cas_oidc_client_secret = var.cas_oidc_client_secret
}

module "ces-blueprint" {
  source = "./ces-blueprint"
  depends_on = [module.ces-core]

  dogu_registry_password = var.dogu_registry_password
  dogu_registry_username = var.dogu_registry_username

  cas_oidc_client_secret = var.cas_oidc_client_secret
  cas_oidc_config = var.cas_oidc_config

  ces_admin_email = var.ces_admin_email
  ces_admin_username = var.ces_admin_username
  ces_admin_password = var.ces_admin_password
  ces_certificate_key_path = var.ces_certificate_key_path
  ces_certificate_path = var.ces_certificate_path
  ces_namespace = var.ces_namespace
  ces_fqdn = var.ces_fqdn

  dogus = var.dogus

}

