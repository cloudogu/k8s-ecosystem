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
  min_master_version = var.kubernetes_version

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }
  maintenance_policy {
    // GKE has no support for time zones as clusters are global
    // time zone is always GMT
    // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#daily_maintenance_window
    daily_maintenance_window {
      start_time = "23:00"
      end_time   = "03:00"
    }
    maintenance_exclusion {
      exclusion_name = "work hours"
      start_time     = "06:00"
      end_time       = "20:00"
    }
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

resource "google_container_node_pool" "default_node_pool" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.default.id
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    spot         = var.spot_vms
    machine_type = var.machine_type
    disk_type    = var.disk_type
    disk_size_gb = var.disk_size

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}