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

variable "cas_oidc_enabled" {
  description = "Specifies if the ecosystem should provide the possibility to log in with an external oidc authenticator."
  type = bool
  default = false
}

variable "cas_oidc_discovery_uri" {
  description = <<EOT
  Describes the URI containing the description for the target provider's OIDC protocol. Must point to the openid-connect
  configuration. This is usually structured as follows: `https://[base-server-url]/.well-known/openid-configuration`."
  EOT
  type = string
}

variable "cas_oidc_client_id" {
  description = "Contains the identifier to be used to identify the CAS to the OIDC provider."
  type = string
}

variable "cas_oidc_client_secret" {
  description = "Contains the secret to be used together with the client ID to identify the CAS to the OIDC provider. Encrypted."
  type = string
}

variable "cas_oidc_display_name" {
  description = "The display name is used for the OIDC provider on the user interface."
  type = string
}

variable "cas_oidc_optional" {
  description = <<EOT
  Specifies whether authentication via the configured OIDC provider is optional. The user will be automatically
  redirected to the OIDC provider login page if this property is set to 'false'. The 'true' entry makes authentication
  via the OIDC provider optional. This is done by displaying an additional button for the OIDC provider on the login
  page of the CAS, which can be used to authenticate with the OIDC provider.
  EOT
  type = bool
  default = false
}

variable "cas_oidc_scopes" {
  description = <<EOT
  Specifies the resource to query against OIDC. Normally, this enumeration should include at least the openid, the
  user's email, profile information, and the groups assigned to the user.
  EOT
  type = list(string)
  default = jsonencode([
    "openid",
    "email",
    "profile",
    "GroupScope"
  ])
}

variable "cas_oidc_principal_attribute" {
  description = <<EOT
  Specifies an attribute that should be used as principal id inside the CES. CAS uses the ID provided by the OIDC
  provider when this property is empty.
  EOT
  type = string
  default = "preferred_username"
}

variable "cas_oidc_attribute_mapping" {
  description = <<EOT
  The attributes provided by OIDC do not exactly match the attributes required by CAS. It is necessary to convert the
  OIDC attributes to attributes accepted by the CAS. Therefore, this entry should contain rules for converting an
  attribute provided by the OIDC vendor to an attribute required by the CAS. The rules should be specified in the
  following format: email:mail,familyname:lastname'. In the given example, the OIDC attributes "email" and "family_name"
  are converted to "mail" and "surname" respectively.
  The CAS needs the following attributes to work properly: 'mail,surname,givenName,username,displayName'.
  EOT
  type = string
  default = "email:mail,family_name:surname,given_name:givenName,preferred_username:username,name:displayName,groups:externalGroups"
}

variable "cas_oidc_allowed_groups" {
  description  = "Specifies cloudogu platform groups whose members can use the platform login. Only relevant if platform login is enabled."
  type         = list(string)
}

variable "cas_oidc_initial_admin_usernames" {
  description  = "Specifies cloudogu platform usernames that are given admin rights in this CES. Only relevant if platform login is enabled."
  type         = list(string)
}