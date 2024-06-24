variable "gcp_project_name" {
  type = string
}

variable "gcp_zone" {
  type    = string
  default = "europe-west3-c"
}

variable "gcp_region" {
  type    = string
  default = "europe-west3"
}

variable "gcp_credentials" {
  type      = string
  sensitive = true
  default   = "../secrets/gcp_sa.json"
}

variable "create_bucket" {
  type = bool
  default = true
}

variable "bucket_name" {
  description = "The name of the bucket"
  type        = string
  default     = "cloudogu-backup-bucket"
}

variable "use_bucket_encryption" {
  type = bool
  default = true
}

variable "key_ring_name" {
  type    = string
  default = "ces-key-ring"
}

variable "key_name" {
  type    = string
  default = "ces-key"
}