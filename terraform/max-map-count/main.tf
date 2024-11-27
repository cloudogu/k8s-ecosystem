terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

resource "kubernetes_daemonset" "max_map_count" {
  metadata {
    name      = "max-map-count"
    namespace = "kube-system"

    labels = {
      app = "max-map-count"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "max-map-count"
      }
    }

    template {
      metadata {
        labels = {
          app = "max-map-count"
        }
      }

      spec {
        node_selector = var.node_selectors

        container {
          name              = "sysctl-set"
          image             = "alpine:3.20.0"
          command           = ["/bin/sh", "-c"]
          args              = ["while true; do sysctl -w vm.max_map_count=262144; sleep 3600; done"]
          image_pull_policy = "IfNotPresent"

          security_context {
            privileged = true
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
