variable "image_registry_url" {
  description = "The url for the docker-image-registry"
  type = string
  default = "registry.cloudogu.com"
}

variable "image_registry_username" {
  description = "The username for the docker-image-registry"
  type = string
}

variable "image_registry_password" {
  description = "The base64-encoded password for the docker-image-registry"
  type = string
  sensitive = true
}

variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type = string
}

variable "dogu_registry_password" {
  description = "The base64-encoded password for the dogu-registry"
  type = string
  sensitive = true
}

variable "dogu_registry_endpoint" {
  description = "The endpoint for the dogu-registry"
  type = string
  default = "https://dogu.cloudogu.com/api/v2/dogus"
}

variable "dogu_registry_url_schema" {
  description = "The URL schema for the dogu-registry ('default' or 'index')"
  type = string
  default = "default"
}

variable "helm_registry_host" {
  description = "The host for the helm-registry"
  type = string
  default = "registry.cloudogu.com"
}

variable "helm_registry_schema" {
  description = "The schema for the helm-registry"
  type = string
  default = "oci"
}

variable "helm_registry_plain_http" {
  description = "A flag which indicates if the component-operator should use plain http for the helm-registry"
  type = bool
  default = false
}

variable "helm_registry_insecure_tls" {
  description = "A flag which indicates if the component-operator should use insecure TLS for the helm-registry"
  type = bool
  default = false
}

variable "helm_registry_username" {
  description = "The username for the helm-registry"
  type = string
}

variable "helm_registry_password" {
  description = "The base64-encoded password for the helm-registry"
  type = string
  sensitive = true
}

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

variable "ces_admin_password" {
  description = "The password for the ces admin user"
  type = string
  sensitive = true
}

variable "additional_dogus" {
  description = "The password for the ces admin user"
  type = list(string)
  default = ["official/jenkins", "official/scm", "official/nexus"]
}

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type = string
  default = ""
}

variable "setup_chart_namespace" {
  description = "The namespace of k8s-ces-setup chart"
  type = string
  default = "k8s"
}

variable "setup_chart_version" {
  description = "The version of the k8s-ces-setup chart"
  type = string
  default = "1.0.0"
}

variable "resource_patches_file" {
  description = "The location of a file containing resource-patches for the CES installation. The file-path is relative to the root-module-location"
  type = string
  default = "resource_patches.yaml"
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
  description = "The size of the disks in GB"
  type = string
  default = "West Europe"
}
