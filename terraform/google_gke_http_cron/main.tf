terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.3"
    }
  }
}

resource "google_cloud_scheduler_job" "http_job" {
  name             = var.name
  description      = var.job_description
  schedule         = var.cron_expression
  time_zone        = var.timer_zone
  attempt_deadline = var.attempt_deadline
  paused           = var.paused
  region           = var.gcp_region

  retry_config {
    retry_count = var.retry_count
  }

  http_target {
    http_method = var.method
    uri         = var.uri
    body        = base64encode(var.body)
    headers     = {
      "Content-Type" = var.content_type
    }

    oauth_token {
      service_account_email = var.service_account_email
    }
  }
}
