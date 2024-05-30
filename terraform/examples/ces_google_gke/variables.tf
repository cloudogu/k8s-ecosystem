variable "gcp_project_name" {
  type = string
}

variable "gcp_zone" {
  type = string
  default = "europe-west3-c"
}

variable "gcp_credentials" {
  type = string
  sensitive = true
}