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
  }

  required_version = ">= 1.7.0"
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.gcp_project_name
  zone        = var.gcp_zone
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.google_gke.endpoint}"
    token                  = module.google_gke.access_token
    cluster_ca_certificate = base64decode(
      module.google_gke.ca_certificate
    )
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

module "google_gke" {
  source             = "../../google_gke"
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  idp_enabled        = var.idp_enabled

  machine_type = var.machine_type
  node_count   = var.node_count
}

module "ces" {
  depends_on = [module.google_gke]
  source     = "../../ces-module"

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