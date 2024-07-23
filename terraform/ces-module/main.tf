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
  tld        = var.ces_fqdn != "" ? "${element( split(".", var.ces_fqdn), length(local.split_fqdn) - 2)}.${element(local.split_fqdn, length(local.split_fqdn) - 1)}" : "k3ces.local"
}

resource "helm_release" "k8s-ces-setup" {
  name       = "k8s-ces-setup2"
  #repository = "${var.helm_registry_schema}://${var.helm_registry_host}/${var.setup_chart_namespace}"
  repository = "${var.helm_registry_schema}://europe-west3-docker.pkg.dev/ces-coder-workspaces/ces-test-docker-helm-repo/charts"
  chart      = "k8s-ces-setup"
  version    = var.setup_chart_version
  namespace        = var.ces_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml.tftpl",
      {
        "dogu_registry_endpoint"     = var.dogu_registry_endpoint
        "dogu_registry_username"     = var.dogu_registry_username
        "dogu_registry_password"     = var.dogu_registry_password
        "dogu_registry_url_schema"   = var.dogu_registry_url_schema
        "docker_registry_url"        = var.image_registry_url
        "docker_registry_username"   = var.image_registry_username
        "docker_registry_password"   = var.image_registry_password
        "helm_registry_host"         = var.helm_registry_host
        "helm_registry_schema"       = var.helm_registry_schema
        "helm_registry_plain_http"   = var.helm_registry_plain_http
        "helm_registry_insecure_tls" = var.helm_registry_insecure_tls
        "helm_registry_username"     = var.helm_registry_username
        "helm_registry_password"     = var.helm_registry_password
        "additional_components"      = var.additional_components
        "setup_json"                 = yamlencode(templatefile(
          "${path.module}/setup.json.tftpl",
          {
            # https://docs.cloudogu.com/en/docs/system-components/ces-setup/operations/setup-json/
            "admin_username" = var.ces_admin_username,
            "admin_password" = var.ces_admin_password,
            "admin_email"    = var.ces_admin_email,
            "default_dogu"   = var.default_dogu,
            "dogus"          = var.dogus,
            "fqdn" : var.ces_fqdn,
            "domain" : local.tld
            "certificateType" : var.ces_certificate_path == null ? "selfsigned" : "external"
            "certificate" : var.ces_certificate_path != null ? replace(file(var.ces_certificate_path), "\n", "\\n") : ""
            "certificateKey" : var.ces_certificate_key_path != null ? replace(file(var.ces_certificate_key_path), "\n", "\\n") : ""
          }
        ))
        "resource_patches" = var.resource_patches
      })
  ]
}