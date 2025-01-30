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
      source  = "mrparkers/keycloak"
      version = "~> 4.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  required_version = ">= 1.7.0"
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.gcp_project_name
  zone        = var.gcp_zone
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
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

module "kubeconfig_generator" {
  source                 = "../../../kubeconfig_generator"
  cluster_name           = var.cluster_name
  access_token           = module.google_gke.access_token
  cluster_ca_certificate = module.google_gke.ca_certificate
  cluster_endpoint       = "https://${module.google_gke.endpoint}"

  kubeconfig_path = "kubeconfig"
}

module "google_gke" {
  source             = "../../../google_gke"
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  idp_enabled        = var.idp_enabled

  node_pool_name = var.node_pool_name
  machine_type   = var.machine_type
  node_count     = var.node_count
}

resource "random_uuid" "ip_address_uuid" {
}

locals {
  ip_address_name = "ces-${random_uuid.ip_address_uuid.result}"
}

resource "google_compute_address" "ip_address" {
  name = local.ip_address_name
}

module "increase_max_map_count" {
  depends_on = [module.google_gke]
  source = "../../../max-map-count"
}

provider "keycloak" {
  client_id     = var.keycloak_service_account_client_id
  client_secret = var.keycloak_service_account_client_secret
  url           = var.keycloak_url
  realm         = var.keycloak_realm_id
}

module "keycloak" {
  providers = {
    keycloak = keycloak
  }
  source   = "../../../keycloak-client-module"
  ces_fqdn = google_compute_address.ip_address.address
}

module "ces" {
  depends_on = [module.google_gke, module.keycloak]
  source = "../../../ces-module"

  # Configure CES installation options
  setup_chart_version   = var.setup_chart_version
  setup_chart_namespace = var.setup_chart_namespace
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
  dogu_registry_endpoint     = var.dogu_registry_endpoint
  dogu_registry_url_schema   = var.dogu_registry_url_schema

  helm_registry_host         = var.helm_registry_host
  helm_registry_schema       = var.helm_registry_schema
  helm_registry_plain_http   = var.helm_registry_plain_http
  helm_registry_insecure_tls = var.helm_registry_insecure_tls
  helm_registry_username     = var.helm_registry_username
  helm_registry_password     = var.helm_registry_password

  cas_oidc_enabled                 = true
  cas_oidc_discovery_uri           = "${var.keycloak_url}/realms/${var.keycloak_realm_id}/.well-known/openid-configuration"
  cas_oidc_client_id               = module.keycloak.external_cas_openid_client_id
  cas_oidc_client_secret           = module.keycloak.external_cas_openid_client_secret
  cas_oidc_display_name            = var.cas_oidc_display_name
  cas_oidc_optional                = var.cas_oidc_optional
  cas_oidc_scopes                  = concat(["openid"], var.keycloak_client_scopes)
  cas_oidc_allowed_groups          = var.cas_oidc_allowed_groups
  cas_oidc_initial_admin_usernames = var.cas_oidc_initial_admin_usernames
}

locals {
  scalingUri            = "https://container.googleapis.com/v1beta1/projects/${var.gcp_project_name}/zones/${var.gcp_zone}/clusters/${var.cluster_name}/nodePools/${var.node_pool_name}/setSize"
  service_account_email = jsondecode(file(var.gcp_credentials)).client_email
}

module "scale_jobs" {
  depends_on = [module.google_gke]
  source   = "../../../google_gke_http_cron"
  for_each = {
    for index, job in var.scale_jobs :
    job.id => job
  }
  name                  = "${var.cluster_name}-scale-to-${each.value.node_count}-job-${index(var.scale_jobs, each.value)}"
  uri                   = local.scalingUri
  method                = "POST"
  content_type          = "application/json"
  body                  = "{\"nodeCount\":${each.value.node_count}}"
  cron_expression       = each.value.cron_expression
  gcp_region            = var.gcp_region
  service_account_email = local.service_account_email
}