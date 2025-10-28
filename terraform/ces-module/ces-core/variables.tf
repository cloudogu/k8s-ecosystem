# component operator crd
variable "component_operator_image" {
  description = "The Image:Version of the component operator. Optional with version like cloudogu/k8s-component-operator:1.10.0"
  type        = string
  default     = "cloudogu/k8s-component-operator:1.10.1"
}

# resource ecosystem itself
variable "ecosystem_core_chart_version" {
  description = "The version of the ecosystem-core chart"
  type        = string
  default     = "0.2.0"
}

variable "ecosystem_core_chart_namespace" {
  description = "The namespace of ecosystem-core chart"
  type        = string
  default     = "k8s"
}

variable "ecosystem_core_timeout" {
  description = "The helm timeout of ecosystem-core to complete the installation in seconds"
  type        = number
  default     = 600
}

# namespace of ces
variable "ces_namespace" {
  description = "The namespace for the CES"
  type        = string
  default     = "ecosystem"
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
      { namespace = "ecosystem", name = "k8s-dogu-operator", version = "3.15.0" },
      { namespace = "ecosystem", name = "k8s-service-discovery", version = "3.0.0" },
      { namespace = "ecosystem", name = "k8s-blueprint-operator-crd", version = "2.0.1", disabled = true},
      { namespace = "ecosystem", name = "k8s-blueprint-operator", version = "3.0.0-CR1" },
      { namespace = "ecosystem", name = "k8s-ces-gateway", version = "1.0.1" },
      { namespace = "ecosystem", name = "k8s-ces-assets", version = "1.0.1" },
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

# helm credentials
variable "helm_registry_host" {
  description = "The host for the helm-registry"
  type        = string
}

variable "helm_registry_schema" {
  description = "The schema for the helm-registry"
  type        = string
}

variable "ces_admin_password" {
  description = "The CES admin password"
  type        = string
  sensitive   = true
}

variable "cas_oidc_client_secret" {
  description = "Contains the secret to be used together with the client ID to identify the CAS to the OIDC provider. Encrypted."
  type        = string
  sensitive   = true
  default     = ""
}

variable "default_dogu" {
  description = "The default Dogu of the EcoSystem"
  type        = string
  default     = "cas"
}

variable "externalIP" {
  description = "Contains the external IP, my overwrite the loadbalancer external ip, defaults to empty -> so the loadbalancer ip will not be patched"
  type        = string
  default     = ""
}
