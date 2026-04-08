# This addition is needed to patch the external IP if it is set from outside like on coder setups

locals {
  # unify empty variable
  ext_ip     = try(trimspace(nonsensitive(var.externalIP)), "")
}

data "kubernetes_service" "ces_lb_exists" {
  metadata {
    name      = "ces-loadbalancer"
    namespace = var.ces_namespace
  }
  depends_on = [helm_release.ecosystem-core]
}