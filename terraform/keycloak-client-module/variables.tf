variable "keycloak_realm_id" {
  description = "Keycloak realm to be used for the External CAS OpenID client"
  default = "Cloudogu"
  type = string
}

variable "ces_fqdn" {
  description = "FQDN or IP address of the CES"
  type = string
  nullable = false
}

variable "keycloak_client_scopes" {
  description = "OIDC scopes to add as default scopes in the keycloak client"
  type = list(string)
  default = ["acr", "email", "groups", "profile", "roles", "web-origins"]
}