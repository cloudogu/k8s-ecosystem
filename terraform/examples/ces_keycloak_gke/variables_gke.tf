variable "gcp_project_name" {
  type = string
}

variable "gcp_credentials" {
  type      = string
  sensitive = true
  default   = "secrets/gcp_sa.json"
}

variable "cluster_name" {
  description = "The cluster name"
  type        = string
}
