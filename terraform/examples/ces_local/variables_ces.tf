variable "image_registry_url" {
  description = "The url for the docker-image-registry"
  type        = string
  default     = "registry.cloudogu.com"
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

variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type        = string
}

variable "dogu_registry_password" {
  description = "The base64-encoded password for the dogu-registry"
  type        = string
  sensitive   = true
}

variable "dogu_registry_endpoint" {
  description = "The endpoint for the dogu-registry"
  type        = string
  default     = "https://dogu.cloudogu.com/api/v2/dogus"
}

variable "dogu_registry_url_schema" {
  description = "The URL schema for the dogu-registry ('default' or 'index')"
  type        = string
  default     = "default"
}

variable "helm_registry_host" {
  description = "The host for the helm-registry"
  type        = string
  default     = "registry.cloudogu.com"
}

variable "helm_registry_schema" {
  description = "The schema for the helm-registry"
  type        = string
  default     = "oci"
}

variable "helm_registry_plain_http" {
  description = "A flag which indicates if the component-operator should use plain http for the helm-registry"
  type        = bool
  default     = false
}

variable "helm_registry_insecure_tls" {
  description = "A flag which indicates if the component-operator should use insecure TLS for the helm-registry"
  type        = bool
  default     = false
}

variable "helm_registry_username" {
  description = "The username for the helm-registry"
  type        = string
}

variable "helm_registry_password" {
  description = "The base64-encoded password for the helm-registry"
  type        = string
  sensitive   = true
}

variable "ces_admin_username" {
  description = "The CES admin username"
  type        = string
  default     = "admin"
}

variable "ces_admin_password" {
  description = "The password for the ces admin user"
  type        = string
  sensitive   = true
}

variable "dogus" {
  description = "A list of Dogus to install"
  type        = list(string)
  default     = [
    "official/ldap:2.6.2-7",
    "official/postfix:3.8.4-1",
    "k8s/nginx-static:1.23.1-6",
    "k8s/nginx-ingress:1.6.4-4",
    "official/cas:7.0.4.1-1",
    "official/jenkins",
    "official/nexus",
    "official/scm"
  ]
}

variable "additional_components" {
  description = "A list of additional Components to install"
  type        = list(object({
    name            = string
    version         = string
    namespace       = string
    deployNamespace = string
  }))
  default = [{ name = "k8s-longhorn", version = "latest", namespace = "k8s", deployNamespace = "longhorn-system" }]
}

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type        = string
  default     = ""
}

variable "setup_chart_namespace" {
  description = "The namespace of k8s-ces-setup chart"
  type        = string
  default     = "k8s"
}

variable "setup_chart_version" {
  description = "The version of the k8s-ces-setup chart"
  type        = string
  default     = "1.0.0"
}

variable "resource_patches_file" {
  description = "The location of a file containing resource-patches for the CES installation. The file-path is relative to the root-module-location"
  type        = string
  default     = "resource_patches.yaml"
}