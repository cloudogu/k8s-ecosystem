terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.19"
    }
  }
}

resource "google_cloud_scheduler_job" "scale_job" {
  for_each = {
    for index, job in var.scale_jobs :
    index => job
  }
  name             = "${var.cluster_name}-${var.node_pool_name}-${each.key}-scale-to-${each.value.node_count}-job"
  description      = "job to scale the nodepool '${var.node_pool_name}' of cluster '${var.cluster_name}' to ${each.value.node_count}"
  schedule         = each.value.cron_expression
  time_zone        = var.timer_zone
  attempt_deadline = var.attempt_deadline
  region           = var.region

  retry_config {
    retry_count = var.retry_count
  }

  http_target {
    http_method = "POST"
    uri         = "https://container.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}/nodePools/${var.node_pool_name}:setSize"
    body = base64encode("{\"nodeCount\":${each.value.node_count}}")
    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = var.service_account_email
    }
  }
}