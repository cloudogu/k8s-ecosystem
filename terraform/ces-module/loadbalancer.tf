locals {
  external_ip     = trimspace(coalesce(try(nonsensitive(var.externalIP), null), " "))
}

resource "kubernetes_manifest" "ces_loadblancer_ip_patch" {
  count = local.external_ip != "" ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "ces-loadbalancer"
      namespace = var.ces_namespace
    }
    spec = {
      loadBalancerIP = local.external_ip
    }
  }

  depends_on      = [helm_release.ecosystem-core]
}