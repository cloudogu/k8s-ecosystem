terraform {
  required_version = ">= 0.14"

  required_providers {
    kubectl = {
      // The official kubectl provider from hashicorp can't be used because it requires crd read permissions on generic cr apply.
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

#provider "kubectl" {
#  config_path = var.gardener_kube_config_path
#}

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
      "name"      = "${var.shoot_name_prefix}${random_string.id.result}"
      //"name"      = var.shoot_name != "" ? var.shoot_name : "${var.shoot_name_prefix}${random_string.id.result}"
      "namespace" = var.garden_namespace
      "annotations" : {
        "confirmation.gardener.cloud/deletion" : var.cluster_removable
      }
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
            systemComponents = {
              allow = false
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
            "name"     = "worker-smbnr"
            "volume"   = {
              "size" = var.node_size
            }
            "zones" = [
              "az1",
            ]
          },
        ]
      }
      "purpose"           = var.purpose
      "region"            = var.region
      "secretBindingName" = var.secret_binding_name
    }
  })
}


// This does not work correctly because you get always 401 return even on non existent values and
// this might not be necessary because the api is not in the shoot cluster.
#locals {
#  clusterName="${var.shoot_name_prefix}${random_string.id.result}"
#}
#
#resource "null_resource" "wait_for_shoot_api" {
#  provisioner "local-exec" {
#    command = "./waitForShootAPI.sh ${local.clusterName} ${var.project_id}"
#  }
#
#  depends_on = [kubectl_manifest.cluster]
#}
