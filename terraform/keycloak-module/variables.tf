variable "keycloak_realm_id" {
  description = "Keycloak realm to be used for the External CAS OpenID client"
  default = "Cloudogu"
  type = string
}

variable "keycloak_url" {
  description = "Keycloak URL to use for creating the External CAS OpenID client"
  nullable = false
  type = string
}

variable "keycloak_service_account_client_id" {
  description = "Keycloak client id to use for creating the External CAS OpenID client"
  nullable = false
  type = string
}

variable "keycloak_service_account_client_secret" {
  description = "Keycloak client secret to use for creating the External CAS OpenID client"
  nullable = false
  type = string
  sensitive = true
}

variable "ces_fqdn" {
  type = string
  nullable = false
}