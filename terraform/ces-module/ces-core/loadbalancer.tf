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

# patch loadbalancer-service "ces-loadbalancer"
resource "kubectl_manifest" "ces_loadbalancer_ip_patch" {
  for_each = local.ext_ip != "" ? { apply = local.ext_ip } : {}

  yaml_body = templatefile(
    "${path.module}/loadbalancer.yaml.tftpl",
    {
      "externalIP"    = each.value,
      "ces_namespace" = var.ces_namespace
    })

  server_side_apply = true

  depends_on        = [data.kubernetes_service.ces_lb_exists]
}