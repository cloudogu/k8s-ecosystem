variable "keycloak_realm_id" {
  description = "Keycloak realm used to create the external CAS OpenID client"
  default = "Cloudogu"
  type = string
}

variable "keycloak_url" {
  description = "Keycloak URL used to create the external CAS OpenID client"
  nullable = false
  type = string
}

variable "keycloak_service_account_client_id" {
  description = "Keycloak client id used to create the external CAS OpenID client"
  nullable = false
  type = string
}

variable "keycloak_service_account_client_secret" {
  description = "Keycloak client secret used to create the external CAS OpenID client"
  nullable = false
  type = string
  sensitive = true
}

variable "keycloak_client_scopes" {
  description = <<EOT
  Specifies the scopes with which to create the keycloak client as well as the resource to query against OIDC.
  Normally, this enumeration should include at least the
  user's email, profile information, and the groups assigned to the user.
  The openid scope will be automatically included in the query against OIDC.
  EOT
  type = list(string)
  default = ["email", "profile", "groups"]
}