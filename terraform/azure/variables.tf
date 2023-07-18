variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "cluster_name" {
  description = "The name of the Azure AKS Cluster"
}

variable "namespace" {
  description = "The namespace for the CES"
  default = "ecosystem"
}

variable "image_registry_username" {
  description = "The username for the docker-image-registry"
}

variable "image_registry_password" {
  description = "The password for the docker-image-registry"
}

variable "image_registry_email" {
  description = "The email for the docker-image-registry"
}

variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
}

variable "dogu_registry_password" {
  description = "The password for the dogu-registry"
}

variable "dogu_registry_endpoint" {
  description = "The endpoint for the dogu-registry"
}

variable "ces_admin_password" {
  description = "The CES admin password"
}