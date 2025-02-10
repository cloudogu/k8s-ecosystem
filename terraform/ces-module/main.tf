terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

locals {
  split_fqdn = split(".", var.ces_fqdn)
  # Top Level Domain extracted from fully qualified domain name. k3ces.local is used for development mode and empty fqdn.
  topLevelDomain = var.ces_fqdn != "" ? "${element( split(".", var.ces_fqdn), length(local.split_fqdn) - 2)}.${element(local.split_fqdn, length(local.split_fqdn) - 1)}": "k3ces.local"
  splitComponentNamespaces = [
    for componentStr in var.components :
    {
      namespace = split("/", componentStr)[0]
      rest      = split("/", componentStr)[1]
      //provoke error here, so that the build fails if no namespace or name is given
    }
  ]
  parsedComponents = [
    for namespaceAndRest in local.splitComponentNamespaces :
    {
      namespace       = namespaceAndRest.namespace
      name            = split(":", namespaceAndRest.rest)[0]
      version         = length(split(":", namespaceAndRest.rest)) == 2 ? split(":", namespaceAndRest.rest)[1] : "latest"
      deployNamespace = split(":", namespaceAndRest.rest)[0] != "k8s-longhorn" ? var.ces_namespace : "longhorn-system"
    }
  ]
  cas_oidc_config_formatted = {
    enabled = var.cas_oidc_config.enabled
    discovery_uri = var.cas_oidc_config.discovery_uri
    client_id = var.cas_oidc_config.client_id
    display_name = var.cas_oidc_config.display_name
    optional = var.cas_oidc_config.optional
    scopes = join(" ", var.cas_oidc_config.scopes)
    principal_attribute = var.cas_oidc_config.principal_attribute
    attribute_mapping = var.cas_oidc_config.attribute_mapping
    allowed_groups = join(", ", var.cas_oidc_config.allowed_groups)
    initial_admin_usernames = join(", ", var.cas_oidc_config.initial_admin_usernames)
  }
}

resource "helm_release" "k8s-ces-setup" {
  name       = "k8s-ces-setup"
  repository = "${var.helm_registry_schema}://${var.helm_registry_host}/${var.setup_chart_namespace}"
  chart      = "k8s-ces-setup"
  version    = var.setup_chart_version

  namespace        = var.ces_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml.tftpl",
      {
        "dogu_registry_endpoint"       = var.dogu_registry_endpoint
        "dogu_registry_username"       = var.dogu_registry_username
        "dogu_registry_password"       = var.dogu_registry_password
        "dogu_registry_url_schema"     = var.dogu_registry_url_schema
        "container_registry_secrets"   = var.container_registry_secrets
        "helm_registry_host"           = var.helm_registry_host
        "helm_registry_schema"         = var.helm_registry_schema
        "helm_registry_plain_http"     = var.helm_registry_plain_http
        "helm_registry_insecure_tls"   = var.helm_registry_insecure_tls
        "helm_registry_username"       = var.helm_registry_username
        "helm_registry_password"       = var.helm_registry_password
        "component_operator_chart"     = var.component_operator_chart
        "component_operator_crd_chart" = var.component_operator_crd_chart
        "components"                   = local.parsedComponents
        "setup_json" = yamlencode(templatefile(
          "${path.module}/setup.json.tftpl",
          {
            # https://docs.cloudogu.com/en/docs/system-components/ces-setup/operations/setup-json/
            "admin_username"  = var.ces_admin_username
            "admin_password"  = var.ces_admin_password
            "admin_email"     = var.ces_admin_email
            "default_dogu"    = var.default_dogu
            "dogus"           = var.dogus
            "fqdn"            = var.ces_fqdn
            "domain"          = local.topLevelDomain
            "certificateType" = var.ces_certificate_path == null ? "selfsigned" : "external"
            "certificate"     = var.ces_certificate_path != null ? replace(file(var.ces_certificate_path), "\n", "\\n") : ""
            "certificateKey" = var.ces_certificate_key_path != null ? replace(file(var.ces_certificate_key_path), "\n", "\\n") : ""

            "cas_oidc_config" = jsonencode(local.cas_oidc_config_formatted)
            "cas_oidc_client_secret" = var.cas_oidc_client_secret
          }
        ))
        "resource_patches" = var.resource_patches
      })
  ]
}