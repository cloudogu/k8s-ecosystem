variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type = string
}

variable "scheduler_region" {
  description = "Region where the scheduler job resides."
  type = string
}

variable "cluster_location" {
  description = "the location of the cluster, e.g. europe-west3-c for a zonal cluster or europe-west3 for a regional cluster."
  type = string
}

variable "node_pool_name" {
  description = "the name of the cluster node pool to scale"
  type = string
}

variable "cluster_name" {
  description = "The name of the cluster to scale based on the schedule. The name will be included in the name of the schedule."
  type = string
}

variable "timer_zone" {
  description = "The time zone from the tz database."
  type = string
  default = "Europe/Berlin"
}

variable "service_account_email" {
  description = "The client email from the used service account for oauth."
  type = string
}

variable "scale_jobs" {
  description = "List of objects defining scale jobs for the cluster node pool, e.g. '0 4 * * 1-5' or '0 18 * * *'"
  type        = list(object({
    node_count      = number
    cron_expression = string
  }))
}

variable "attempt_deadline" {
  description = "the timeout for the scale jobs."
  type = string
  default = "320s"
}

variable "retry_count" {
  description = "The number retries if the scale job fails"
  type = number
  default = 3
}