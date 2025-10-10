# This addition is needed to patch the external IP if it is set from outside like on coder setups

locals {
  # unify empty variable
  ext_ip     = try(trimspace(nonsensitive(var.externalIP)), "")
}

# patch loadbalancer-service "ces-loadbalancer"
resource "kubernetes_manifest" "ces_loadbalancer_ip_patch" {
  count = trim(local.ext_ip) != "" ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "ces-loadbalancer"
      namespace = var.ces_namespace
    }
    spec = {
      loadBalancerIP = local.ext_ip  # ← nur dieses Feld wird von Terraform „besessen“
    }
  }
  depends_on        = [helm_release.ecosystem-core]
}