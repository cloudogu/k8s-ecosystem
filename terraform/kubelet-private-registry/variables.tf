variable "image_registry_url" {
  description = "The url for the docker-image-registry"
  type        = string
}

variable "image_registry_username" {
  description = "The username for the docker-image-registry"
  type        = string
}

variable "image_registry_password" {
  description = "The base64-encoded password for the docker-image-registry"
  type        = string
  sensitive   = true
}