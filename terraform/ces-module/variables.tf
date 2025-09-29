# component operator crd
variable "component_operator_crd_chart" {
  description = "The helm chart of the component crd. Optional with version like k8s/k8s-component-operator-crd:1.2.3"
  type        = string
  default     = "k8s/k8s-component-operator-crd:latest"
}

# blueprint operator crd
variable "blueprint_operator_crd_chart" {
  description = "The helm chart of the blueprint crd. Optional with version like k8s/k8s-blueprint-operator-crd:1.2.3"
  type        = string
  default     = "k8s/k8s-blueprint-operator-crd:latest"
}

# component operator crd
variable "component_operator_image" {
  description = "The Image:Version of the component operator. Optional with version like cloudogu/k8s-component-operator:1.10.0"
  type        = string
  default     = "cloudogu/k8s-component-operator:latest"
}

# component operator crd
variable "ecosystem_core_default_config_image" {
  description = "The Image:Version of the ecosystem_core default config. Optional with version like cloudogu/ecosystem-core-default-config:0.1.0"
  type        = string
  default     = "cloudogu/ecosystem-core-default-config:latest"
}

# resource ecosystem itself
variable "ecosystem_core_chart_version" {
  description = "The version of the ecosystem-core chart"
  type        = string
  default     = "1.0.0"
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
      disabled = bool
    }))
    backup = object ({
      enabled = bool
      components = list(object({
        namespace = string
        name = string
        version = string
        disabled = bool
      }))
    })
    monitoring = object ({
      enabled = bool
      components = list(object({
        namespace = string
        name = string
        version = string
        disabled = bool
      }))
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


# ----------------------------------------------------------




variable "ecosystem_core_chart_namespace" {
  description = "The namespace of ecosystem-core chart"
  type        = string
  default     = "ecosystem"
}

variable "ecosystem_core_timeout" {
  description = "The helm timeout of ecosystem-core to complete the installation in seconds"
  type        = number
  default     = 300
}

variable "setup_fqdn_from_loadbalancer_wait_timeout_mins" {
  description = "The timeout of the setup to wait for the fqdn from the loadbalancer in minutes"
  type        = number
  default     = 15
}

variable "setup_dogu_wait_timeout_secs" {
  description = "The timeout of the setup to wait for each dogu in seconds"
  type        = number
  default     = 300
}

variable "setup_component_wait_timeout_secs" {
  description = "The timeout of the setup to wait for each component in seconds"
  type        = number
  default     = 1800
}



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



variable "default_dogu" {
  description = "The default Dogu of the EcoSystem"
  type        = string
  default     = "cas"
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






variable "container_registry_secrets" {
  description = "A list of credentials for container registries used by dogus and components. The password must be base64 encoded. The regular configuration would contain registry.cloudogu.com as url."
  type = list(object({
    url      = string
    username = string
    password = string
  }))
}



variable "dogu_registry_endpoint" {
  description = "The endpoint for the dogu-registry"
  type        = string
}

variable "dogu_registry_url_schema" {
  description = "The URL schema for the dogu-registry ('default' or 'index')"
  type        = string
  default     = "default"
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



variable "resource_patches" {
  description = "The content of the resource-patches for the CES installation."
  type        = string
  default     = ""
}

variable "is_setup_applied_matching_resource" {
  description = "This variable defines a resource with its kind, api and field selector and is used to determine if the setup has already been executed or not."
  type = object({
    kind           = string
    api            = string
    field_selector = string
  })
  default = {
    kind           = "CustomResourceDefinition",
    api            = "apiextensions.k8s.io/v1",
    field_selector = "metadata.name==dogus.k8s.cloudogu.com"
  }
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