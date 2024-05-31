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
  name       = local.node_pool_name
  cluster    = google_container_cluster.default.id
  node_count = var.node_count

  node_config {
    preemptible  = true
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

locals {
  scalingUri = "https://container.googleapis.com/v1beta1/projects/${var.gcp_project_name}/zones/${var.gcp_zone}/clusters/${var.cluster_name}/nodePools/${local.node_pool_name}/setSize"
  service_account_email = jsondecode(file(var.gcp_credentials)).client_email
}

resource "google_cloud_scheduler_job" "scale_down_job" {
  count            = var.weekend_scale_down ? 1 : 0
  name             = "${var.cluster_name}-scale_down_job"
  description      = "This job scales the cluster down every Friday evening to save resources."
  schedule         = "0 18 * * FRI"
  time_zone        = "Etc/UTC"
  attempt_deadline = "320s"
  paused           = false
  region           = var.gcp_region

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = local.scalingUri
    body        = base64encode("{\"nodeCount\":0}")
    headers     = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = local.service_account_email
    }
  }
}

resource "google_cloud_scheduler_job" "scale_up_job" {
  count            = var.weekend_scale_down ? 1 : 0
  name             = "${var.cluster_name}-scale_up_job"
  description      = "This job scales the cluster up every Monday morning."
  schedule         = "0 4 * * MON"
  time_zone        = "Etc/UTC"
  attempt_deadline = "320s"
  paused           = false
  region           = var.gcp_region

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = local.scalingUri
    body        = base64encode("{\"nodeCount\":${var.node_count}")
    headers     = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = local.service_account_email
    }
  }
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}