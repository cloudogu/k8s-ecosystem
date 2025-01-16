terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubectl" {
  config_path = var.kube_config_path
}

resource "openstack_networking_floatingip_v2" "ip" {
  pool = "public"
  count = 1
}

// TODO. Creat correct shoot configuration via UI if credentials are available and use variables.
resource "kubectl_manifest" "cluster" {
  yaml_body = yamlencode({
    kind : "Shoot"
    apiVersion : "core.gardener.cloud/v1beta1"
    metadata : {
      namespace : "garden-ma-24"
      confirmation.gardener.cloud/deletion: "true"
    }
    name : "terraform-test"
    spec : {
      provider : {
        type : "openstack"
        infrastructureConfig : {
          apiVersion : "openstack.provider.extensions.gardener.cloud/v1alpha1"
          kind : "InfrastructureConfig"
          networks : {
            workers : "10.250.0.0/16"
          }
          floatingPoolName : "ext01"
        }
        controlPlaneConfig : {
          apiVersion : "openstack.provider.extensions.gardener.cloud/v1alpha1"
          kind : "ControlPlaneConfig"
          loadBalancerProvider : "amphora"
        }
        workers : [
          {
            name : "k8s-worker"
            minimum : 1
            maximum : 2
            maxSurge : 1
            machine : {
              type : "SCS-2V:4:100"
              image : {
                name : ubuntu
                version : 22.4.2
              }
              architecture : amd64
            }
            zones : ["nova"]
            cri : {
              name : "containerd"
            }
            volume : {
              size : "50Gi"
            }
          }
        ]
        networking : {
          nodes : "10.250.0.0/16"
          type : "cilium"
        }
        cloudProfileName : "pluscloudopen-hire"
        secretBindingName : "my-openstack-secret"
        region : "RegionOne"
        purpose : "evaluation"
        kubernetes : {
          version : "1.27.5"
          enableStaticTokenKubeconfig : false
        }
        addons : {
          kubernetesDashboard : {
            enabled : "false"
          }
          nginxIngress : {
            enabled : "false"
          }
        }
        maintenance : {
          timeWindow : {
            begin : "010000+0200"
            end : "020000+0200"
          }
          autoUpdate : {
            kubernetesVersion : true
            machineImageVersion : true
          }
        }
        hibernation : {
          schedules : [
            {
              start : "00 17 * * 1, 2, 3, 4,5"
              location : Europe/Berlin
            }
          ]
        }
        controlPlane : {
          highAvailability : {
            failureTolerance : {
              type : "none"
            }
          }
        }
      }
    }
  })
}
