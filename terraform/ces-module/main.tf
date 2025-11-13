# The local Closure converts input Parameter to usable template parameters
locals {
  // enforce version
  blueprint_operator_crd_chart = length(split(":", var.blueprint_operator_crd_chart)) == 2 ? var.blueprint_operator_crd_chart : var.blueprint_operator_crd_chart + ":3.1.0"
  component_operator_crd_chart = length(split(":", var.component_operator_crd_chart)) == 2 ? var.component_operator_crd_chart : var.component_operator_crd_chart + ":1.10.1"
  component_operator_image = length(split(":", var.component_operator_image)) == 2 ? var.component_operator_image : var.component_operator_image + ":latest"

  disabled_blueprint_crd_comp = { name = "k8s-blueprint-operator-crd", disabled = true}

  k8s_ces_assets_with_default_dogu = {
    name = "k8s-ces-assets",
    valuesObject = yamlencode({
      nginx = {
        manager = {
          config = {
            defaultDogu = var.default_dogu
          }
        }
      }
    })
  }

  #### sanitize components ####
  components_normalized = coalesce(var.components.components, [])

  # clean blueprint crd and k8s-ces-assets from components
  components_without_blueprint_crd = [
    for comp in local.components_normalized : comp
    if comp.name != local.disabled_blueprint_crd_comp.name
  ]

  components_cleaned = [
    for comp in local.components_without_blueprint_crd : comp
    if comp.name != local.k8s_ces_assets_with_default_dogu.name
  ]

  # extract k8s-ces-assets candidate from components list
  k8s_ces_assets_comp_candidate = [
    for comp in local.components_normalized : comp
    if comp.name == local.k8s_ces_assets_with_default_dogu.name
  ]

  # merge k8s-ces-assets candidate to use the default dogu from config
  k8s_ces_assets_comp = (
    length(local.k8s_ces_assets_comp_candidate) > 0 ?
    merge(
      local.k8s_ces_assets_comp_candidate,
      local.k8s_ces_assets_with_default_dogu
    ) :
    local.k8s_ces_assets_with_default_dogu
  )

  # assemble sanitized list of components
  components_sanitized = concat(
    local.components_cleaned,
    [local.disabled_blueprint_crd_comp],
    [local.k8s_ces_assets_comp]
  )
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
  blueprint_operator_crd_chart = local.blueprint_operator_crd_chart

  create_namespace = var.create_namespace
  ces_namespace    = var.ces_namespace

  externalIP = var.externalIP
}

module "ces-core" {
  source = "./ces-core"
  depends_on = [module.ces-preparation]

  helm_registry_host = var.helm_registry_host
  helm_registry_schema = var.helm_registry_schema

  ces_namespace = var.ces_namespace

  component_operator_image = local.component_operator_image

  components = {
    components = local.components_sanitized
    backup     = var.components.backup
    monitoring = var.components.monitoring
  }

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

