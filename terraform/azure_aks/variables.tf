variable "azure_client_id" {
  description = "The azure client id"
  type = string
  sensitive = true
}

variable "azure_client_secret" {
  description = "The azure client secret"
  type = string
  sensitive = true
}

variable "aks_cluster_name" {
  description = "The azure cluster name"
  type = string
  default = "test-terraform-module"
}

variable "node_pool_name" {
  description = "The name of the default node pool"
  type = string
  default = "default"
}

variable "node_count" {
  description = "The amount of nodes to create"
  type = number
  default = 3
}

variable "vm_size" {
  description = "The vm size of the default node pool"
  type = string
  default = "Standard_DC4s_v2"
}

variable "os_disk_size_gb" {
  description = "The size of the disks in GB"
  type = number
  default = 50
}

variable "azure_resource_group_location" {
  description = "Location of the cluster VMs"
  type = string
  default = "West Europe"
}

variable "tags" {
  description = "tags to add at all azure resources"
  type = map(string)
  default = {}
}