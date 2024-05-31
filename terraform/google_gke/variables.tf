locals {
  node_pool_name = "${var.cluster_name}-${var.node_pool_name}"
}

variable "kubernetes_version" {
  default = "1.29"
}

variable "node_pool_name" {
  description = "The name of the node pool. The final node pool will be create with the cluster name as prefix."
  type = string
  default = "node-pool"
}

variable "node_count" {
  default = "1"
}

variable "machine_type" {
  default = "n1-standard-4" // "e2-medium" "n1-standard-4"
}

variable "disk_type" {
  type = string
  default = "pd-balanced" // (e.g. 'pd-standard', 'pd-ssd' or 'pd-balanced')
}

variable "disk_size" {
  type = string
  default = 50
}

variable "cluster_name" {
  type = string
}

variable "idp_enabled" {
  type    = bool
  default = false
}

variable "gcp_credentials" {
  type = string
  sensitive = true
  default = "secrets/gcp_sa.json"
}

variable "weekend_scale_down" {
  type = bool
  default = false
  description = "Flag which determines if the cluster should be scaled down on weekend"
}

variable "gcp_project_name" {
  type = string
}

variable "gcp_zone" {
  type = string
}

variable "gcp_region" {
  type = string
}
