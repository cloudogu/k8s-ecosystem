terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.17"
    }
    google = {
      source  = "hashicorp/google"
      version = "~>6.19"
    }
  }

  required_version = ">= 1.10.0"
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.gcp_project_name
  zone        = var.gcp_zone
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
    url      = "${local.helm_registry_schema}://${local.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}