variable "node_pool_name" {
  description = "The name of the node pool."
  type        = string
  default     = "default"
}

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

variable "machine_type" {
  default = "custom-4-6144" // "e2-medium" "n1-standard-4" "custom-4-6144" (4 cores - 6gb ram), "custom-4-8192" (4 cores - 8gb ram)
}

variable "cluster_name" {
  description = "The cluster name"
  type        = string
}