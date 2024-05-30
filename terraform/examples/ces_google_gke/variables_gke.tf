variable "kubernetes_version" {
  default = "1.29"
}
//TODO: node_pool name, disk_size

variable "node_count" {
  description = "The amount of nodes to create"
  type = number
  default = 3
}

variable "machine_type" {
  default = "n1-standard-4" // "e2-medium" "n1-standard-4"
}

variable "cluster_name" {
  description = "The cluster name"
  type = string
}

variable "idp_enabled" {
  type    = bool
  default = false
}