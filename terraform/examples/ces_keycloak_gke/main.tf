locals {
  gke_module_host  = "https://${module.google_gke.endpoint}"
  gke_module_token = module.google_gke.access_token
  gke_module_ca_certificate = base64decode(module.google_gke.ca_certificate)

  helm_registry_schema = "oci"
  helm_registry_host   = "registry.cloudogu.com"

  external_cas_openid_client_id = "ces-${random_uuid.external_cas_openid_client_uuid.result}"

  ip_address_name = "ces-${random_uuid.ip_address_uuid.result}"
}

module "google_gke" {
  source             = "../../google_gke"
  cluster_name       = var.cluster_name
  kubernetes_version = "1.31"
  idp_enabled        = false

  node_pool_name = "default"
  machine_type   = "n1-standard-4"
  node_count     = 3
}

resource "random_uuid" "ip_address_uuid" {
}

resource "google_compute_address" "ip_address" {
  name = local.ip_address_name
}

resource "random_uuid" "external_cas_openid_client_uuid" {
  lifecycle {
    ignore_changes = all
  }
}

module "keycloak" {
  providers = {
    keycloak = keycloak
  }
  source        = "../../keycloak-client-module"
  realm_id      = "Cloudogu"
  client_id     = local.external_cas_openid_client_id
  login_theme   = "cloudogu"
  client_scopes = var.keycloak_client_scopes
  ces_fqdn      = google_compute_address.ip_address.address
}

module "ces" {
  depends_on = [module.google_gke, module.keycloak]
  source = "../../ces-module"

  # Configure CES installation options
  component_operator_crd_chart        = var.component_operator_crd_chart
  blueprint_operator_crd_chart        = var.blueprint_operator_crd_chart
  component_operator_image            = var.component_operator_image
  ecosystem_core_default_config_image = var.ecosystem_core_default_config_image
  ces_fqdn              = google_compute_address.ip_address.address
  ces_admin_username    = var.ces_admin_username
  ces_admin_password    = var.ces_admin_password
  dogus                 = var.dogus

  # TODO
  # resource_patches = templatefile("resource_patches.yaml.tftpl", {
  #   external_ip = google_compute_address.ip_address.address,
  # })

  externalIP = google_compute_address.ip_address.address

  components = var.components

  # Configure access for the registries. Passwords need to be base64-encoded.
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password

  docker_registry_host       = var.docker_registry_host
  docker_registry_username   = var.docker_registry_username
  docker_registry_password   = var.docker_registry_password
  docker_registry_email      = var.docker_registry_email

  helm_registry_host     = local.helm_registry_host
  helm_registry_schema   = local.helm_registry_schema
  helm_registry_username = var.helm_registry_username
  helm_registry_password = var.helm_registry_password

  cas_oidc_config = {
    enabled                 = true
    discovery_uri           = "${var.keycloak_url}/realms/${var.keycloak_realm_id}/.well-known/openid-configuration"
    client_id               = local.external_cas_openid_client_id
    display_name            = "CAS oidc provider"
    optional                = var.cas_oidc_optional
    scopes = concat(["openid"], var.keycloak_client_scopes)
    allowed_groups          = var.cas_oidc_allowed_groups
    initial_admin_usernames = var.cas_oidc_initial_admin_usernames
  }
  cas_oidc_client_secret = module.keycloak.client_secret
}