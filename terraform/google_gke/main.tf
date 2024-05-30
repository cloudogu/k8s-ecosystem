terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.3"
    }
  }
}

resource "google_container_cluster" "default" {
  name               = var.cluster_name
  initial_node_count = var.node_count
  min_master_version = var.kubernetes_version
  node_version       = var.kubernetes_version

  release_channel {
    channel = "REGULAR"
  }

  node_config {
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }


  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }

  identity_service_config {
    enabled = var.idp_enabled
  }

  deletion_protection = false
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}