terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.31.1"
    }
    keycloak = {
      source = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }

  required_version = ">= 1.7.0"
}

provider "google" {
  credentials = "secrets/gcp_sa.json"
  project     = var.gcp_project_name
  zone        = "europe-west3-c"
}

locals {
  gke_module_host  = "https://${module.google_gke.endpoint}"
  gke_module_token = module.google_gke.access_token
  gke_module_ca_certificate = base64decode(module.google_gke.ca_certificate)
}

provider "kubernetes" {
  host                   = local.gke_module_host
  token                  = local.gke_module_token
  cluster_ca_certificate = local.gke_module_ca_certificate
}

locals {
  helm_registry_schema = "oci"
  helm_registry_host   = "registry.cloudogu.com"
}

provider "helm" {
  kubernetes {
    host                   = local.gke_module_host
    token                  = local.gke_module_token
    cluster_ca_certificate = local.gke_module_ca_certificate
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }

  registry {
    url      = "${local.helm_registry_schema}://${local.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

module "google_gke" {
  source             = "../../google_gke"
  cluster_name       = var.cluster_name
  kubernetes_version = "1.30"
  idp_enabled        = false

  node_pool_name = "default"
  machine_type   = "n1-standard-4"
  node_count     = 3
}

resource "random_uuid" "ip_address_uuid" {
}

locals {
  ip_address_name = "ces-${random_uuid.ip_address_uuid.result}"
}

resource "google_compute_address" "ip_address" {
  name = local.ip_address_name
}

provider "keycloak" {
  client_id     = var.keycloak_service_account_client_id
  client_secret = var.keycloak_service_account_client_secret
  url           = var.keycloak_url
  realm         = var.keycloak_realm_id
}

resource "random_uuid" "external_cas_openid_client_uuid" {
  lifecycle {
    ignore_changes = all
  }
}

locals {
  external_cas_openid_client_id = "ces-${random_uuid.external_cas_openid_client_uuid.result}"
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
  setup_chart_version   = "3.3.1"
  setup_chart_namespace = "k8s"
  ces_fqdn              = google_compute_address.ip_address.address
  ces_admin_username    = var.ces_admin_username
  ces_admin_password    = var.ces_admin_password
  dogus                 = var.dogus
  resource_patches = templatefile("resource_patches.yaml.tftpl", {
    external_ip = google_compute_address.ip_address.address,
  })
  component_operator_chart     = var.component_operator_chart
  component_operator_crd_chart = var.component_operator_crd_chart
  components = var.components

  # Configure access for the registries. Passwords need to be base64-encoded.
  container_registry_secrets = var.container_registry_secrets
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password
  dogu_registry_endpoint     = "https://dogu.cloudogu.com/api/v2/dogus"

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
    scopes = join(" ", concat(["openid"], var.keycloak_client_scopes))
    allowed_groups          = join(", ", var.cas_oidc_allowed_groups)
    initial_admin_usernames = join(", ", var.cas_oidc_initial_admin_usernames)
  }
  cas_oidc_client_secret = module.keycloak.client_secret
}