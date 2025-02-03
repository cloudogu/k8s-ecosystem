variable "setup_chart_version" {
  description = "The version of the k8s-ces-setup chart"
  type        = string
  default     = "3.0.4"
}

variable "setup_chart_namespace" {
  description = "The namespace of k8s-ces-setup chart"
  type        = string
  default     = "k8s"
}

variable "ces_namespace" {
  description = "The namespace for the CES"
  type        = string
  default     = "ecosystem"
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

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type        = string
}

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
    "k8s/nginx-static",
    "k8s/nginx-ingress",
    "official/cas"
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

variable "container_registry_secrets" {
  description = "A list of credentials for container registries used by dogus and components. The password must be base64 encoded. The regular configuration would contain registry.cloudogu.com as url."
  type = list(object({
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
}

variable "dogu_registry_url_schema" {
  description = "The URL schema for the dogu-registry ('default' or 'index')"
  type        = string
  default     = "default"
}

variable "helm_registry_host" {
  description = "The host for the helm-registry"
  type        = string
}

variable "helm_registry_schema" {
  description = "The schema for the helm-registry"
  type        = string
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
    enabled                 = string
    discovery_uri           = string
    client_id               = string
    display_name            = string
    optional                = string
    scopes                  = string
    attribute_mapping       = string
    principal_attribute     = string
    allowed_groups          = string
    initial_admin_usernames = string
  })
  default = {
    enabled                 = false
    discovery_uri           = ""
    client_id               = ""
    display_name            = "CAS oidc provider"
    optional                = false
    scopes                  = "openid email profile groups"
    attribute_mapping       = "email:mail,family_name:surname,given_name:givenName,preferred_username:username,name:displayName,groups:externalGroups"
    principal_attribute     = "preferred_username"
    allowed_groups          = ""
    initial_admin_usernames = ""
  }
}

variable "cas_oidc_client_secret" {
  description = "Contains the secret to be used together with the client ID to identify the CAS to the OIDC provider. Encrypted."
  type = string
  sensitive = true
  default = ""
}