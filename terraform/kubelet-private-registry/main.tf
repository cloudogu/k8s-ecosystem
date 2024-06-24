terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}


locals {
  registries_map = { for reg in var.private_registries : reg.url => base64encode("${reg.username}:${base64decode(reg.password)}")}
}

resource "kubernetes_secret" "kubelet-private-registry-secret" {
  metadata {
    name = "kubelet-config"
    namespace = "kube-system"
  }
  type = "Opaque"

  data = {
    ".config.json" = jsonencode({
      "auths" = local.registries_map
    })
  }
}

resource "kubernetes_manifest" "kubelet-private-registry-daemonset" {
  manifest = yamldecode(file("${path.module}/manifests/kubelet_private_registry-daemonset.yaml"))
}