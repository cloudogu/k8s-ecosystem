terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.12.1"
    }
  }
}

locals {
  split_fqdn = split(".", var.ces_fqdn)
  # Top Level Domain extracted from fully qualified domain name
  tld        = "${element( split(".", var.ces_fqdn), length(local.split_fqdn) - 2)}.${element(local.split_fqdn, length(local.split_fqdn) - 1)}"
}


provider "helm" {
  kubernetes {
    host                   = var.kubernetes_host
    client_certificate     = var.kubernetes_client_certificate
    client_key             = var.kubernetes_client_key
    cluster_ca_certificate = var.kubernetes_cluster_ca_certificate
  }

  registry {
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = var.helm_registry_password
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
        "setup_json"                 = yamlencode(templatefile(
          "${path.module}/setup.json.tftpl",
          {
            # https://docs.cloudogu.com/en/docs/system-components/ces-setup/operations/setup-json/
            "admin_username"   = var.ces_admin_username,
            "admin_password"   = var.ces_admin_password,
            "admin_email"      = var.ces_admin_email,
            "additional_dogus" = var.additional_dogus,
            "fqdn" : var.ces_fqdn,
            "domain" : local.tld
            "certificateType" : var.ces_certificate_path == null ? "selfsigned" : "external"
            "certificate" : var.ces_certificate_path != null ? replace(file(var.ces_certificate_path), "\n", "\\n") : ""
            "certificateKey" : var.ces_certificate_key_path != null ? replace(file(var.ces_certificate_key_path), "\n", "\\n") : ""
          }
        ))
        "resource_patches" = var.resource_patches_file != null ? file("${path.root}/${var.resource_patches_file}") : ""
      })
  ]
}