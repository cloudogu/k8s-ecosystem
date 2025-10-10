# This addition is needed to patch the external IP if it is set from outside like on coder setups

locals {
  # unify empty variable
  ext_ip     = try(trimspace(nonsensitive(var.externalIP)), "")
}

# patch loadbalancer-service "ces-loadbalancer"
resource "kubernetes_manifest" "ces_loadbalancer_ip_patch" {
  manifest = yamldecode(templatefile("${path.module}/loadbalancer.yaml.tftpl", {
    "ces_namespace" = var.ces_namespace,
    "externalIP"    = local.ext_ip
  }))
  depends_on        = [helm_release.ecosystem-core]
}