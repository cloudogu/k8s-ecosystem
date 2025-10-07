locals {
  ext_ip     = try(trimspace(nonsensitive(var.externalIP)), "")
}

resource "kubectl_manifest" "ces_loadbalancer_ip_patch" {
  yaml_body = templatefile(
    "${path.module}/loadbalancer.yaml.tftpl",
    {
      "externalIP"    = local.ext_ip,
      "ces_namespace" = var.ces_namespace
    })

  server_side_apply = true

  depends_on        = [helm_release.ecosystem-core]
}