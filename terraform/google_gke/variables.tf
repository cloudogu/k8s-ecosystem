variable "kubernetes_version" {
  default = "1.30"
}

variable "node_pool_name" {
  description = "The name of the node pool."
  type        = string
  default     = "default"
}

variable "preemptible" {
  description = "Decide if the cluster should use preemtible VMs which are cheaper but will be replaced within 24h."
  type        = bool
  default     = false
}

variable "spot_vms" {
  description = "Decide if the cluster should provision spot VMs. This drastically reduces costs but gives no availability guarantees."
  type        = bool
  default     = false
}

variable "machine_type" {
  default = "n1-standard-4" // "e2-medium" "n1-standard-4" "custom-4-6144" (4 cores - 6gb ram)
}

variable "disk_type" {
  type    = string
  default = "pd-balanced" // (e.g. 'pd-standard', 'pd-ssd' or 'pd-balanced')
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = 40
}

variable "cluster_name" {
  type = string
}

variable "cluster_labels" {
  description = "labels for the GKE cluster, which will be propagated to all underlying resources like GCE disks."
  type = map(string)
  default = {}
}

variable "node_pool_labels" {
  description = "labels for the GKE node pool, which will be propagated to all underlying resources like GCE disks."
  type = map(string)
  default = {}
}

variable "idp_enabled" {
  type    = bool
  default = false
}

variable "node_count" {
  type        = number
  description = "The amount of nodes."
}
