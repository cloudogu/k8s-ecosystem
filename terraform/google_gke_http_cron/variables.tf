variable "gcp_region" {
  type = string
}

variable "name" {
  description = "The name of the job displayed in the google console."
  type = string
}

variable "job_description" {
  description = "The description of the job displayed in the google console."
  type = string
  default = ""
}

variable "cron_expression" {
  description = "The cron expression e.g. '0 4 * * MON'"
  type = string
}

variable "timer_zone" {
  description = "The time zone from the tz database."
  type = string
  default = "Europe/Berlin"
}

variable "attempt_deadline" {
  type = string
  default = "320s"
}

variable "paused" {
  type = bool
  default = false
}

variable "retry_count" {
  type = number
  default = 1
}

variable "method" {
  type = string
}

variable "uri" {
  type = string
}

variable "body" {
  type = string
}

variable "content_type" {
  type = string
}

variable "service_account_email" {
  description = "The client email from the used service account for oauth."
  type = string
}
