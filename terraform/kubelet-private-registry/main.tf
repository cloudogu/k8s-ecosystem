terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

resource "kubernetes_manifest" "kubelet-private-registry-secret" {
  computed_fields = ["stringData"]
  manifest = yamldecode(templatefile("${path.module}/manifests/kubelet_private_registry-secret.yaml.tpl", {
    "image_registry_url"  = var.image_registry_url
    "image_registry_auth" = base64encode("${var.image_registry_username}:${base64decode(var.image_registry_password)}")
  }))
}

resource "kubernetes_manifest" "kubelet-private-registry-daemonset" {
  manifest = yamldecode(file("${path.module}/manifests/kubelet_private_registry-daemonset.yaml"))
}