terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

resource "kubernetes_manifest" "increase-max-map-count-daemonset" {
  manifest = yamldecode(templatefile("${path.module}/manifests/max_map_count.yaml.tpl", {
    "node_selectors" = var.node_selectors,
  }))
}