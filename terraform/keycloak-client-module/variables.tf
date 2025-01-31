variable "realm_id" {
  description = "Keycloak realm to be used for the External CAS OpenID client"
  type = string
  nullable = false
}

variable "client_id" {
  description = "ID of the created keycloak client"
  type = string
  nullable = false
}

variable "description" {
  description = "Description for the created keycloak client"
  type = string
  default = "CES client created via Terraform"
}

variable "client_scopes" {
  description = "OIDC scopes to add as default scopes in the keycloak client"
  type = list(string)
  default = ["email", "groups", "profile"]
}

variable "login_theme" {
  description = "The client login theme. This will override the default theme for the realm."
  type = string
}

variable "ces_fqdn" {
  description = "FQDN or IP address of the CES"
  type = string
  nullable = false
}