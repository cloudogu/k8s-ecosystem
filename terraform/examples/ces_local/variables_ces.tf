variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type        = string
}

variable "dogu_registry_password" {
  description = "The base64-encoded password for the dogu-registry"
  type        = string
  sensitive   = true
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

variable "helm_registry_username" {
  description = "The username for the helm-registry"
  type        = string
}

variable "helm_registry_password" {
  description = "The base64-encoded password for the helm-registry"
  type        = string
  sensitive   = true
}

# docker credentials
variable "docker_registry_host" {
  description = "The host for the docker-registry"
  type        = string
}

variable "docker_registry_username" {
  description = "The username for the docker-registry"
  type        = string
}

variable "docker_registry_email" {
  description = "The email for the docker-registry"
  type        = string
}

variable "docker_registry_password" {
  description = "The base64-encoded password for the docker-registry"
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
  description = "A list of Dogus to install, optional with version like official/cas:7.0.8-3"
  type = list(string)
  default = [
    "official/ldap",
    "official/postfix",
    "k8s/nginx-static",
    "k8s/nginx-ingress",
    "official/cas"
  ]
}

variable "ces_namespace" {
  description = "The namespace for the CES"
  type        = string
  default     = "ecosystem"
}

# component operator crd
variable "component_operator_crd_chart" {
  description = "The helm chart of the component crd. Optional with version like k8s/k8s-component-operator-crd:1.2.3"
  type        = string
  default     = "k8s/k8s-component-operator-crd:1.10.1"
}

# component operator crd
variable "component_operator_image" {
  description = "The Image:Version of the component operator. Optional with version like cloudogu/k8s-component-operator:1.10.0"
  type        = string
  default     = "cloudogu/k8s-component-operator:1.10.1"
}

# List of cómponents, backup components and monitoring components
variable "components" {
  description = "A list of credentials for container registries used by dogus and components. The password must be base64 encoded. The regular configuration would contain registry.cloudogu.com as url."
  type = object ({
    components = list(object({
      namespace = string
      name = string
      version = string
      helmNamespace = optional(string)
      disabled = optional(bool, false)
      valuesObject = optional(any, null)
    }))
    backup = object ({
      enabled = bool
      components = list(object({
        namespace = string
        name = string
        version = string
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      }))
    })
    monitoring = object ({
      enabled = bool
      components = list(object({
        namespace = string
        name = string
        version = string
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      }))
    })
  })
  default = {
    components = [
      { namespace = "ecosystem", name = "k8s-dogu-operator-crd", version = "2.9.0" },
      { namespace = "ecosystem", name = "k8s-dogu-operator", version = "3.13.0" },
      { namespace = "ecosystem", name = "k8s-service-discovery", version = "3.0.0" },
      { namespace = "ecosystem", name = "k8s-blueprint-operator-crd", version = "1.3.0", disabled = true},
      { namespace = "ecosystem", name = "k8s-blueprint-operator", version = "2.7.0" },
      { namespace = "ecosystem", name = "k8s-ces-gateway", version = "1.0.4" },
      { namespace = "ecosystem", name = "k8s-ces-assets", version = "1.0.3" },
      { namespace = "ecosystem", name = "k8s-ces-control", version = "1.7.1", disabled = true },
      { namespace = "ecosystem", name = "k8s-debug-mode-operator-crd", version = "0.2.3"},
      { namespace = "ecosystem", name = "k8s-debug-mode-operator", version = "0.3.0"},
      { namespace = "ecosystem", name = "k8s-support-mode-operator-crd", version = "0.2.0", disabled = true },
      { namespace = "ecosystem", name = "k8s-support-mode-operator", version = "0.3.0", disabled = true },
    ]
    backup = {
      enabled = true
      components = [
        { namespace = "ecosystem", name = "k8s-backup-operator-crd", version = "1.6.0" },
        { namespace = "ecosystem", name = "k8s-backup-operator", version = "1.6.0" },
        { namespace = "ecosystem", name = "k8s-velero", version = "10.0.1-5" },
      ]
    }
    monitoring = {
      enabled = true
      components = [
        { namespace = "ecosystem", name = "k8s-prometheus", version = "75.3.5-3" },
        { namespace = "ecosystem", name = "k8s-minio", version = "2025.6.13-2" },
        { namespace = "ecosystem", name = "k8s-loki", version = "3.3.2-4" },
        { namespace = "ecosystem", name = "k8s-promtail", version = "2.9.1-9" },
        { namespace = "ecosystem", name = "k8s-alloy", version = "1.1.2-1" },
      ]
    }
  }
}

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type        = string
  default     = ""
}