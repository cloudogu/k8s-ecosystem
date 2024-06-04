variable "kubernetes_version" {
  default = "1.29"
}

variable "node_pool_name" {
  description = "The name of the node pool."
  type = string
  default = "default"
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

variable "node_count" {
  type = number
  description = "The amount of nodes."
}
