# This addition is needed to patch the external IP if it is set from outside like on coder setups

locals {
  has_ip   = can(trim(var.externalIP)) && trim(var.externalIP) != ""
  base     = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "ces-loadbalancer"
      namespace = var.ces_namespace
    }
  }
  patch    = local.has_ip ? {
    spec = { loadBalancerIP = var.externalIP }
  } : {}

  # Manifest = Basis + optionaler Patch
  manifest = merge(local.base, local.patch)
}

import {
  to = kubernetes_manifest.ces_loadbalancer_ip_patch
  id = "apiVersion=v1,kind=Service,namespace=${var.ces_namespace},name=ces-loadbalancer"
}

# patch loadbalancer-service "ces-loadbalancer"
resource "kubernetes_manifest" "ces_loadbalancer_ip_patch" {
  manifest = local.manifest
  depends_on        = [helm_release.ecosystem-core]
}