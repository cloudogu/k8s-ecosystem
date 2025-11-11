# component operator image
variable "component_operator_image" {
  description = "The Image:Version of the component operator. Optional with version like cloudogu/k8s-component-operator:1.10.0"
  type        = string
}

# resource ecosystem itself
variable "ecosystem_core_chart_version" {
  description = "The version of the ecosystem-core chart"
  type        = string
}

variable "ecosystem_core_chart_namespace" {
  description = "The namespace of ecosystem-core chart"
  type        = string
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
}

# List of components, backup components and monitoring components
variable "components" {
  description = "A list of components, ordered by default components, backup and monitoring."
  type = object ({
    components = optional(list(object({
      namespace = optional(string)
      name = string
      version = optional(string)
      helmNamespace = optional(string)
      disabled = optional(bool, false)
      valuesObject = optional(any, null)
    })))
    backup = object ({
      enabled = bool
      components = optional(list(object({
        namespace = optional(string)
        name = string
        version = optional(string)
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      })))
    })
    monitoring = object ({
      enabled = bool
      components = optional(list(object({
        namespace = optional(string)
        name = string
        version = optional(string)
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      })))
    })
  })
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
}

variable "default_dogu" {
  description = "The default Dogu of the EcoSystem"
  type        = string
}

variable "externalIP" {
  description = "Contains the external IP, my overwrite the loadbalancer external ip, defaults to empty -> so the loadbalancer ip will not be patched"
  type        = string
}
