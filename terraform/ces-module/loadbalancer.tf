locals {
  # nur fürs Trigger-Gate ent-sensitivieren; leer wenn null/"":
  ext_ip = try(trimspace(nonsensitive(var.externalIP)), "")
}

resource "null_resource" "ces_loadbalancer_ip_patch" {
  # triggert neu, wenn Namespace oder IP sich ändern
  triggers = {
    ns = var.ces_namespace
    ip = local.ext_ip
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      set -euo pipefail
      ip="${var.externalIP}"   # Terraform setzt hier leer, wenn null/"".
      if [ -n "$ip" ]; then
        kubectl -n ${var.ces_namespace} patch svc ces-loadbalancer \
          --type=merge \
          -p '{"spec":{"loadBalancerIP":"'"$ip"'"}}'
      else
        echo "externalIP nicht gesetzt – Patch wird übersprungen."
      fi
    EOT
  }

  depends_on = [helm_release.ecosystem-core]
}