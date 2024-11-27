variable "container_registry_secrets" {
  description = "A list of credentials for container registries used by dogus and components. The password must be base64 encoded. The regular configuration would contain registry.cloudogu.com as url."
  type        = list(object({
    url      = string
    username = string
    password = string
  }))
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

variable "azure_client_id" {
  description = "The azure client id"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "The azure client secret"
  type        = string
  sensitive   = true
}

variable "azure_resource_group_location" {
  description = "The size of the disks in GB"
  type        = string
  default     = "West Europe"
}

variable "aks_cluster_name" {
  description = "The azure cluster name"
  type        = string
  default     = "test-terraform-module"
}

variable "ces_admin_password" {
  description = "The password for the ces admin user"
  type        = string
  sensitive   = true
}

variable "dogus" {
  description = "A list of Dogus to install, optional with version like official/cas:7.0.8-3"
  type        = list(string)
  default     = [
    "official/ldap",
    "official/postfix",
    "k8s/nginx-static",
    "k8s/nginx-ingress",
    "official/cas",
    "official/jenkins",
    "official/nexus",
    "official/scm"
  ]
}

variable "component_operator_crd_chart" {
  description = "The helm chart of the component crd. Optional with version like k8s/k8s-component-operator-crd:1.2.1"
  type = string
  default = "k8s/k8s-component-operator-crd:latest"
}

variable "component_operator_chart" {
  description = "The helm chart of the component operator. Optional with version like k8s/k8s-component-operator:1.2.1"
  type = string
  default = "k8s/k8s-component-operator:latest"
}

variable "components" {
  description = "A list of components to install, optional with version like k8s/k8s-dogu-operator:3.0.1"
  type = list(string)
  default = [
    "k8s/k8s-dogu-operator",
    "k8s/k8s-dogu-operator-crd",
    "k8s/k8s-service-discovery",
  ]
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
  default     = "3.0.4"
}

variable "resource_patches_file" {
  description = "The location of a file containing resource-patches for the CES installation. The file-path is relative to the root-module-location"
  type        = string
  default     = "resource_patches.yaml"
}

variable "node_pool_name" {
  description = "The name of the default node pool"
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "The amount of nodes to create"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "The vm size of the default node pool"
  type        = string
  default     = "Standard_DC4s_v2"
}

variable "os_disk_size_gb" {
  description = "The size of the disks in GB"
  type        = number
  default     = 50
}
