# This addition is needed to patch the external IP if it is set from outside like on coder setups

# Manifest dynamisch zusammenbauen (nur mit spec.loadBalancerIP, wenn gesetzt)
locals {
  has_ip = trim(var.externalIP) != ""

  manifest = merge({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "ces-loadbalancer"
      namespace = var.ces_namespace
    }
  }, local.has_ip ? {
    spec = { loadBalancerIP = var.externalIP }
  } : {})
}

# Patch via kubectl_manifest (SSA)
resource "kubectl_manifest" "ces_loadbalancer_ip" {
  yaml_body         = yamlencode(local.manifest)
  # SSA einschalten + Field Manager setzen
  server_side_apply = true
  # nur falls du bewusst Ownership-Konflikte überschreiben willst -> true
  force_conflicts   = false
}