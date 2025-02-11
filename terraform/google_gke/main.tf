terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.19"
    }
  }
}

resource "google_container_cluster" "default" {
  name               = var.cluster_name
  resource_labels    = var.cluster_labels
  min_master_version = var.kubernetes_version

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  // activate Dataplane 2, so that cilium can be used for network policies
  // FIXME: currently, mn-ces does not support cilium as network policies seem to be more restricitve there
  //datapath_provider                        = "ADVANCED_DATAPATH"
  //enable_cilium_clusterwide_network_policy = true
  cost_management_config {
    // with this flag, we can see costs based on k8s-namespaces, labels etc.
    enabled = true
  }

  release_channel {
    channel = "REGULAR"
  }
  maintenance_policy {
    // GKE has no support for time zones as clusters are global
    // time zone is always GMT
    // the end_time is no real date but only used to calculate the duration of the window if recurrence is set.
    // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#recurring_window
    recurring_window {
      start_time = "2024-09-16T23:00:00Z"
      end_time   = "2024-09-17T03:00:00Z"
      recurrence = "FREQ=DAILY"
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

  // needed since provider version 6 if terraform should also destroy the cluster later
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

    resource_labels = var.node_pool_labels

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