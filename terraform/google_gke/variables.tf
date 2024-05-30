variable "kubernetes_version" {
  default = "1.29"
}

variable "node_count" {
  default = "1"
}

variable "machine_type" {
  default = "n1-standard-4" // "e2-medium" "n1-standard-4"
}

variable "cluster_name" {
  type = string
}

variable "idp_enabled" {
  type    = bool
  default = false
}

