variable "kubeconfig_path" {
  description = "the path to save the kubeconfig file. If no path is provided, no file will be created"
  type = string
  default = null
}

variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
  sensitive = true
}

variable "access_token" {
  type = string
  sensitive = true
  default = ""
}

variable "client_key" {
  type = string
  sensitive = true
  default = ""
}

