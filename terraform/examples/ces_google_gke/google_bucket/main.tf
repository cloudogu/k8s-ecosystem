terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.31.1"
    }
  }
  backend "gcs" {}

  required_version = ">= 1.7.0"
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.gcp_project_name
  zone        = var.gcp_zone
}


module "backup_bucket" {
  count          = var.create_bucket ? 1 : 0
  source         = "../../../google_cloud_storage_bucket"
  project        = var.gcp_project_name
  name           = var.bucket_name
  location       = var.gcp_region
  use_encryption = var.use_bucket_encryption
  key_ring_name  = var.key_ring_name
  key_name       = var.key_name
}