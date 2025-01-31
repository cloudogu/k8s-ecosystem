terraform {
  required_version = ">= 1.7.0"

  required_providers {
    keycloak = {
      source = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

resource "random_password" "client_secret" {
  length = 32
  lifecycle {
    ignore_changes = all
  }
}

resource "keycloak_openid_client" "external_cas_openid_client" {
  realm_id  = var.realm_id
  client_id = var.client_id
  description = var.description

  access_type              = "CONFIDENTIAL"
  client_secret            = random_password.client_secret.result
  standard_flow_enabled    = true
  service_accounts_enabled = true
  authorization {
    policy_enforcement_mode          = "ENFORCING"
    decision_strategy                = "UNANIMOUS"
    allow_remote_resource_management = true
  }

  root_url = "http://${var.ces_fqdn}/cas"
  base_url = "http://${var.ces_fqdn}/cas"
  valid_redirect_uris = [
    "http://${var.ces_fqdn}/cas/*",
    "https://${var.ces_fqdn}/cas/*"
  ]
  web_origins = ["http://${var.ces_fqdn}"]
  admin_url   = "http://${var.ces_fqdn}/cas"
  login_theme = var.login_theme
}

resource "keycloak_openid_client_default_scopes" "external_cas_openid_client_scopes" {
  realm_id       = var.realm_id
  client_id      = keycloak_openid_client.external_cas_openid_client.id
  default_scopes = var.client_scopes
}
