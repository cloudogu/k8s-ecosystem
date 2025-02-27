resource "random_string" "id" {
  length  = 8
  special = false
  upper   = false
}

resource "kubectl_manifest" "cluster" {
  yaml_body = yamlencode({
    "apiVersion" = "core.gardener.cloud/v1beta1"
    "kind"       = "Shoot"
    "metadata"   = {
      "name"      = var.shoot_name != "" ? var.shoot_name : "${var.shoot_name_prefix}${random_string.id.result}"
      "namespace" = var.garden_namespace
      "annotations" : {
        "confirmation.gardener.cloud/deletion" : var.cluster_removable
      }
      labels = var.shoot_labels
    }
    "spec" = {
      "addons" = {
        "kubernetesDashboard" = {
          "enabled" = false
        }
        "nginxIngress" = {
          "enabled" = false
        }
      }
      "cloudProfileName" = var.cloud_profile_name
      "controlPlane"     = {
        "highAvailability" = {
          "failureTolerance" = {
            "type" = "node"
          }
        }
      }
      "hibernation" = {
        "enabled"   = var.hibernation
        "schedules" = var.hibernation_schedules
      }
      "kubernetes" = {
        "enableStaticTokenKubeconfig" = false
        "version"                     = var.kubernetes_version
      }
      "maintenance" = {
        "autoUpdate" = {
          "kubernetesVersion"   = true
          "machineImageVersion" = true
        }
        "timeWindow" = {
          "begin" = "030000+0100"
          "end"   = "040000+0100"
        }
      }
      "networking" = {
        "nodes" = "10.250.0.0/16"
        "type"  = var.networking_type
      }
      "provider" = {
        "controlPlaneConfig" = {
          "apiVersion"           = "openstack.provider.extensions.gardener.cloud/v1alpha1"
          "kind"                 = "ControlPlaneConfig"
          "loadBalancerProvider" = "amphora"
        }
        "infrastructureConfig" = {
          "apiVersion"       = "openstack.provider.extensions.gardener.cloud/v1alpha1"
          "floatingPoolName" = "ext01"
          "kind"             = "InfrastructureConfig"
          "networks"         = {
            "workers" = "10.250.0.0/16"
          }
        }
        "type"    = "openstack"
        "workers" = [
          {
            "systemComponents" = {
              "allow" = true
            }
            "taints" = [
              {
                "effect" = "NoSchedule"
                "key" = "node.gardener.cloud/critical-component"
                "value" = "true"
              }
            ]
            "cri" = {
              "name" = "containerd"
            }
            "machine" = {
              "architecture" = "amd64"
              "image"        = {
                "name"    = var.image_name
                "version" = var.image_version
              }
              "type" = var.system_machine_type
            }
            "maxSurge" = var.system_max_surge
            "maximum"  = var.system_node_max
            "minimum"  = var.system_node_min
            "name"     = "worker-system"
            "volume"   = {
              "size" = var.system_node_size
            }
            "zones" = [
              "az1",
            ]
          },
          {
            "systemComponents" = {
              "allow" = false
            }
            "cri" = {
              "name" = "containerd"
            }
            "machine" = {
              "architecture" = "amd64"
              "image"        = {
                "name"    = var.image_name
                "version" = var.image_version
              }
              "type" = var.machine_type
            }
            "maxSurge" = var.max_surge
            "maximum"  = var.node_max
            "minimum"  = var.node_min
            "name"     = "worker-ces"
            "volume"   = {
              "size" = var.node_size
            }
            "zones" = var.zones
          },
        ]
      }
      "purpose"           = var.purpose
      "region"            = var.region
      "secretBindingName" = var.secret_binding_name
    }
  })
}
