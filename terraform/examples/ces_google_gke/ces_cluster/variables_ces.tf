
variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type        = string
}

variable "dogu_registry_password" {
  description = "The base64-encoded password for the dogu-registry"
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
  description = "A list of Dogus to install, optional with version like official/cas:7.0.8-10"
  type        = list(string)
  default     = [
    "official/ldap",
    "official/postfix",
    "official/cas",
    "official/jenkins",
    "official/scm"
  ]
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

# List of components, backup components and monitoring components
variable "components" {
  description = "A list of components, ordered by default components, backup and monitoring."
  type = object ({
    components = optional(list(object({
      namespace = string
      name = string
      version = string
      helmNamespace = optional(string)
      disabled = optional(bool, false)
      valuesObject = optional(any, null)
    })))
    backup = object ({
      enabled = bool
      components = optional(list(object({
        namespace = string
        name = string
        version = string
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      })))
    })
    monitoring = object ({
      enabled = bool
      components = optional(list(object({
        namespace = string
        name = string
        version = string
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      })))
    })
  })
  default = {
    backup = {
      enabled = true
    }
    monitoring = {
      enabled = true
    }
  }
}

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type        = string
  default     = ""
}