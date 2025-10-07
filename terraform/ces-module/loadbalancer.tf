locals {
  external_ip     = try(nonsensitive(var.externalIP), "")
}

resource "kubernetes_manifest" "ces_loadblancer_ip_patch" {
  manifest = merge(
    {
      apiVersion = "v1"
      kind       = "Service"
      metadata = {
        name      = "ces-loadbalancer"
        namespace = var.ces_namespace
      }
    },
      trimspace(local.external_ip) != "" ? { spec = { loadBalancerIP = var.externalIP } } : {}
  )

  depends_on      = [helm_release.ecosystem-core]
}