terraform {
  required_version = ">= 1.5.0"

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "keycloak" {
  client_id = var.keycloak_service_account_client_id
  client_secret = var.keycloak_service_account_client_secret
  url       = var.keycloak_url
  realm = var.keycloak_realm_id
}

resource "random_uuid" "external_cas_openid_client_uuid" {
  keepers = {
    openid_client = keycloak_openid_client.external_cas_openid_client.id
  }
}

locals {
  external_cas_openid_client_id = "ces-${random_uuid.external_cas_openid_client_uuid[0].result}"
}

resource "random_password" "external_cas_openid_client_secret" {
  keepers = {
    openid_client = keycloak_openid_client.external_cas_openid_client.id
  }
  length = 32
}

resource "keycloak_openid_client" "external_cas_openid_client" {
  realm_id    = var.keycloak_realm_id
  client_id   = local.external_cas_openid_client_id

  access_type = "CONFIDENTIAL"
  client_secret = random_password.external_cas_openid_client_secret[0].result
  standard_flow_enabled = true
  service_accounts_enabled = true
  authorization {
    policy_enforcement_mode = "ENFORCING"
    decision_strategy = "UNANIMOUS"
    allow_remote_resource_management = true
  }

  root_url = "http://${var.ces_fqdn}/cas"
  base_url = "http://${var.ces_fqdn}/cas"
  valid_redirect_uris = [
    "http://${var.ces_fqdn}/cas/*",
    "https://${var.ces_fqdn}/cas/*"
  ]
  web_origins = ["http://${var.ces_fqdn}"]
  admin_url = "http://${var.ces_fqdn}/cas"
  login_theme = "cloudogu"
}

resource "keycloak_openid_client_default_scopes" "external_cas_openid_client_scopes" {
  realm_id  = var.keycloak_realm_id
  client_id = keycloak_openid_client.external_cas_openid_client[0].id
  default_scopes = ["acr", "email", "groups", "profile", "roles", "web-origins"]
}