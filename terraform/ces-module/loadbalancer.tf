locals {
  ext_ip     = try(trimspace(nonsensitive(var.externalIP)), "")
  has_ext_ip = local.ext_ip != ""
}

resource "kubectl_manifest" "ces_loadbalancer_ip_patch" {
  count = local.has_ext_ip ? 1 : 0

  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ces-loadbalancer
  namespace: ${var.ces_namespace}
spec:
  loadBalancerIP: ${var.externalIP}
YAML

  server_side_apply = true


  depends_on = [helm_release.ecosystem-core]
}