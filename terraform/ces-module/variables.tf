# component operator crd
variable "component_operator_crd_chart" {
  description = "The helm chart of the component crd. Optional with version like k8s/k8s-component-operator-crd:1.2.3"
  type        = string
  default     = "k8s/k8s-component-operator-crd"
}

# component operator crd
variable "blueprint_operator_crd_chart" {
  description = "The helm chart of the blueprint crd. Optional with version like k8s/k8s-blueprint-operator-crd:1.2.3"
  type        = string
  default     = "k8s/k8s-blueprint-operator-crd"
}

# resource ecosystem itself
variable "ecosystem_core_chart_version" {
  description = "The version of the ecosystem-core chart"
  type        = string
  default     = ""
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

variable "create_namespace" {
  description = "Flag to specify whether the namespace in variable ces_namespace shall be created"
  type = bool
  default = false
}

# namespace of ces
variable "ces_namespace" {
  description = "The namespace for the CES"
  type        = string
  default     = "ecosystem"
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
    backup = optional(object ({
      enabled = bool
      components = optional(list(object({
        namespace = optional(string)
        name = string
        version = optional(string)
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      })))
    }))
    monitoring = optional(object ({
      enabled = bool
      components = optional(list(object({
        namespace = optional(string)
        name = string
        version = optional(string)
        helmNamespace = optional(string)
        disabled = optional(bool, false)
        valuesObject = optional(any, null)
      })))
    }))
  })
  default = {}
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

# dogu registry credentials
variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type        = string
}

variable "dogu_registry_password" {
  description = "The base64-encoded password for the dogu-registry"
  type        = string
  sensitive   = true
}

# FQDN
variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type        = string
}

# Certificate
variable "ces_certificate_path" {
  # Dev Cert:  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=US/ST=Oregon/L=Portland/O=CompanyName/OU=DepartmentName/CN=example.com"
  description = "The certificate of the EcoSystem in PEM format. If null, a self-signed cert is created. If an intermediate certificate is used it also has to be entered here. The certificate chain has to be in the right order: The instance certificate first, intermediate certificate(s) second and at last the root certificate."
  type        = string
  default     = null
}

variable "ces_certificate_key_path" {
  description = " The certificate key of the EcoSystem in PEM format"
  type        = string
  default     = null
}

# CES Admin
variable "ces_admin_username" {
  description = "The CES admin username"
  type        = string
  default     = "admin"
}

variable "ces_admin_password" {
  description = "The CES admin password"
  type        = string
  sensitive   = true
}

variable "ces_admin_email" {
  description = "The CES admin email address"
  type        = string
  default     = "admin@admin.admin"
}


variable "dogus" {
  description = "A list of Dogus to install, optional with version like official/cas:7.0.8-3"
  type = list(string)
  default = [
    "official/ldap",
    "official/postfix",
    "official/cas"
  ]
}

variable "default_dogu" {
  description = "The default Dogu of the EcoSystem"
  type        = string
  default     = "cas"
}

variable "cas_oidc_config" {
  description = "Configuration of an external cas oidc authenticator. For more information [see here](https://docs.cloudogu.com/en/docs/dogus/cas/operations/Configure_OIDC_Provider/)"
  type = object({
    enabled             = string
    discovery_uri       = string
    client_id           = string
    display_name        = string
    optional            = string
    scopes = list(string)
    attribute_mapping   = string
    principal_attribute = string
    allowed_groups = list(string)
    initial_admin_usernames = list(string)
  })
  default = {
    enabled             = false
    discovery_uri       = ""
    client_id           = ""
    display_name        = "CAS oidc provider"
    optional            = false
    scopes = ["openid", "email", "profile", "groups"]
    attribute_mapping   = "email:mail,family_name:surname,given_name:givenName,preferred_username:username,name:displayName,groups:externalGroups"
    principal_attribute = "preferred_username"
    allowed_groups = []
    initial_admin_usernames = []
  }
}

variable "cas_oidc_client_secret" {
  description = "Contains the secret to be used together with the client ID to identify the CAS to the OIDC provider. Encrypted."
  type        = string
  sensitive   = true
  default     = ""
}

variable "externalIP" {
  description = "Contains the external IP, may overwrite the loadbalancer external ip, defaults to empty -> so the loadbalancer ip will not be patched"
  type        = string
  default     = ""
}
