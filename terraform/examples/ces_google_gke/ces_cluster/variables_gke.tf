variable "kubernetes_version" {
  default = "1.29"
}

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
  default = "n1-standard-4" // "e2-medium" "n1-standard-4" "custom-4-6144" (4 cores - 6gb ram)
}

variable "disk_type" {
  type    = string
  default = "pd-balanced" // (e.g. 'pd-standard', 'pd-ssd' or 'pd-balanced')
}

variable "disk_size" {
  type    = string
  default = 50
}

variable "cluster_name" {
  description = "The cluster name"
  type        = string
}

variable "idp_enabled" {
  type    = bool
  default = false
}

variable "weekend_scale_down" {
  type        = bool
  default     = true
  description = "Flag which determines if the cluster should be scaled down on weekend"
}

variable "node_count" {
  description = "The amount of nodes to create"
  type        = number
  default     = 3
}

variable "scale_jobs" {
  description = "List of objects defining scaling jobs for the cluster. Use different ids here because they are used for the name generation."
  type        = list(object({
    id              = number
    node_count      = number
    cron_expression = string
  }))
  default = [
    {
      node_count      = 0
      cron_expression = "0 18 * * *"
      id              = 0
    },
    {
      node_count      = 3
      cron_expression = "0 4 * * 1-5"
      id              = 1
    }
  ]
}