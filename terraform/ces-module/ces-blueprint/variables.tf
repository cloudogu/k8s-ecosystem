# namespace of ces
variable "ces_namespace" {
  description = "The namespace for the CES"
  type        = string
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
}

variable "ces_certificate_key_path" {
  description = " The certificate key of the EcoSystem in PEM format"
  type        = string
}

# CES Admin
variable "ces_admin_username" {
  description = "The CES admin username"
  type        = string
}

variable "ces_admin_password" {
  description = "The CES admin password"
  type        = string
  sensitive   = true
}

variable "ces_admin_email" {
  description = "The CES admin email address"
  type        = string
}


variable "dogus" {
  description = "A list of Dogus to install, optional with version like official/cas:7.0.8-3"
  type = list(string)
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
}

variable "cas_oidc_client_secret" {
  description = "Contains the secret to be used together with the client ID to identify the CAS to the OIDC provider. Encrypted."
  type        = string
  sensitive   = true
}

# Blueprint
variable "blueprint" {
  description = "Predefined Blueprint. If this Parameter is set, the dogu-parameter will be ignored"
  type        = string
}

