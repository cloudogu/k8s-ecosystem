variable "kubernetes_version" {
  default = "1.29"
}

variable "node_pool_name" {
  description = "The name of the node pool. The final node pool will be create with the cluster name as prefix."
  type = string
  default = "node-pool"
}

variable "gcp_project_name" {
  type = string
}

variable "gcp_zone" {
  type = string
  default = "europe-west3-c"
}

variable "gcp_region" {
  type = string
  default = "europe-west3"
}

variable "gcp_credentials" {
  type = string
  sensitive = true
  default = "secrets/gcp_sa.json"
}

variable "node_count" {
  description = "The amount of nodes to create"
  type = number
  default = 3
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
  description = "The cluster name"
  type = string
}

variable "idp_enabled" {
  type    = bool
  default = false
}

variable "weekend_scale_down" {
  type = bool
  default = true
  description = "Flag which determines if the cluster should be scaled down on weekend"
}