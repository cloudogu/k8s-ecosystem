terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}


locals {
  registries_map = {
    for reg in var.private_registries : reg.url => {
      auth = base64encode("${reg.username}:${base64decode(reg.password)}")
    }
  }
}

resource "kubernetes_secret" "kubelet-private-registry-secret" {
  metadata {
    name      = "kubelet-config"
    namespace = "kube-system"
  }
  type = "Opaque"

  data = {
    "config.json" = jsonencode({
      "auths" = local.registries_map
    })
  }
}

resource "kubernetes_daemonset" "registry_config" {
  metadata {
    name      = "registry-config"
    namespace = "kube-system"
  }

  spec {
    selector {
      match_labels = {
        name = "registry-config"
      }
    }

    template {
      metadata {
        labels = {
          name = "registry-config"
        }
      }

      spec {
        volume {
          name = "host-root"

          host_path {
            path = "/"
          }
        }

        volume {
          name = "config-volume"

          secret {
            secret_name = "kubelet-config"
          }
        }

        container {
          name    = "update-kublet-config"
          image   = "alpine:3.20.0"
          command = ["/bin/sh", "-c"]
          args    = ["while true; do cp -v /config/config.json /host/var/lib/kubelet/config.json; sleep 3600; done"]

          volume_mount {
            name       = "host-root"
            mount_path = "/host"
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/config"
          }
        }

        host_network = true
        host_pid     = true
        host_ipc     = true

        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }

        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}