terraform {
  required_version = ">= 0.14"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}

provider "kubectl" {
  alias       = "kubectl-garden"
  config_path = var.gardener_kube_config_path
}

provider "kubernetes" {
  alias = "kubernetes_garden"

  config_path = var.gardener_kube_config_path
}

provider "kubernetes" {
  alias = "kubernetes_shoot"

  host                   = "https://${local.shoot_api_host}"
  cluster_ca_certificate = data.kubernetes_config_map.cluster-ca.data["ca.crt"]

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "./scripts/kubeConfigExec.sh"
    args        = [
      var.gardener_kube_config_path, module.plusserver.shoot_name, var.garden_namespace, var.gardener_identity
    ]
  }
}

provider "helm" {
  alias = "helm_shoot"

  kubernetes {
    host                   = "https://${local.shoot_api_host}"
    cluster_ca_certificate = data.kubernetes_config_map.cluster-ca.data["ca.crt"]

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "./scripts/kubeConfigExec.sh"
      args        = [
        var.gardener_kube_config_path, module.plusserver.shoot_name, var.garden_namespace, var.gardener_identity
      ]
    }
  }

  registry {
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

locals {
  shootCaNameSuffix = ".ca-cluster"
  // We only use this data source in order to use the generated name in the kubernetes provider config.
  // If we would use the output variable module.plusserver.shoot_name the plan and apply phase would return an error.
  shoot_api_host    = "api.${trimsuffix(data.kubernetes_config_map.cluster-ca.metadata[0].name, local.shootCaNameSuffix)}.${var.project_id}.projects.prod.gardener.get-cloud.io"
}

resource "null_resource" "binary_trigger" {
  triggers = {
    gardenctl = var.gardenctl_source
    gardenlogin = var.gardenlogin_source
  }
}

resource null_resource download_garden_bins {
  depends_on = [null_resource.binary_trigger]

  lifecycle {
    replace_triggered_by = [null_resource.binary_trigger]
  }

  provisioner local-exec {
    command = "./scripts/downloadBins.sh ${var.gardenctl_source} ${var.gardenctl_sha256} ${var.gardenlogin_source} ${var.gardenlogin_sha256}"
  }

  provisioner local-exec {
    when    = destroy
    command = "rm -f ./bin/gardenctl ./bin/gardenlogin"
  }
}

module "plusserver" {
  providers = {
    kubectl = kubectl.kubectl-garden
  }

  depends_on = [null_resource.download_garden_bins]

  source                    = "../../plusserver"
  gardener_kube_config_path = var.gardener_kube_config_path
  garden_namespace          = var.garden_namespace
  //shoot_name                = var.shoot_name
  project_id                = var.project_id
  secret_binding_name       = var.secret_binding_name
  networking_type           = var.networking_type
  max_surge                 = var.max_surge
  node_max                  = var.node_max
  node_min                  = var.node_min
  hibernation               = var.hibernation
}

data "kubernetes_config_map" "cluster-ca" {
  provider   = kubernetes.kubernetes_garden
  depends_on = [null_resource.wait_for_shoot_ca]

  metadata {
    name      = "${module.plusserver.shoot_name}.ca-cluster"
    namespace = var.garden_namespace
  }
}

// Wait for config map to be created
resource "null_resource" "wait_for_shoot_ca" {
  depends_on = [module.plusserver]

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource null_resource get_api_url {
  depends_on = [data.kubernetes_config_map.cluster-ca]
  provisioner "local-exec" {
    command = "./scripts/waitForShootAPI.sh ${module.plusserver.shoot_name} ${var.project_id}"
  }
}

// Create namespace without putting it into terraform state because it would block terraform destroy due to finalizers.
resource "null_resource" "create_namespace_ecosystem" {
  provisioner "local-exec" {
    command = "./scripts/createNamespace.sh ${var.gardener_kube_config_path} ${var.garden_namespace} ${module.plusserver.shoot_name} ecosystem"
  }

  depends_on = [null_resource.get_api_url]
}


// In general the service-discovery would create this loadbalancer service.
// Updating the service-discovery maybe requires updating this resource.
resource "kubernetes_service_v1" "ces-loadbalancer" {
  metadata {
    name        = "ces-loadbalancer"
    annotations = {
      "loadbalancer.openstack.org/keep-floatingip" : "false"
      // We have to persist the cluster name to get the correct kubeconfig in the destroy provisioner because the provisioner
      // can only access self attributes.
      shoot-name : module.plusserver.shoot_name
      gardener-kube-config-path-name : var.gardener_kube_config_path
      gardener-namespace : var.garden_namespace
    }
    labels = {
      app : "ces"

    }
    namespace = "ecosystem"
  }
  // If another ingress controller is used we have to update the spec. (Currently only nginx-ingress exists)
  spec {
    port {
      name        = "nginx-ingress-80"
      port        = 80
      target_port = 80
    }
    port {
      name        = "nginx-ingress-443"
      port        = 443
      target_port = 443
    }
    type     = "LoadBalancer"
    selector = {
      "dogu.name" : "nginx-ingress"
    }
  }

  lifecycle {
    ignore_changes = all
  }

  depends_on = [null_resource.create_namespace_ecosystem]

  provider = kubernetes.kubernetes_shoot

  provisioner "local-exec" {
    when    = destroy
    command = "./scripts/releaseLoadBalancerIP.sh ${self.metadata[0].annotations.gardener-kube-config-path-name} ${self.metadata[0].annotations.gardener-namespace} ${self.metadata[0].annotations.shoot-name} ecosystem"
  }
}

locals {
  // Don't worry, this works...
  externalIP = kubernetes_service_v1.ces-loadbalancer.status.0.load_balancer.0.ingress.0.ip
}

module "ces" {
  providers = {
    helm       = helm.helm_shoot
    kubernetes = kubernetes.kubernetes_shoot
  }

  depends_on = [kubernetes_service_v1.ces-loadbalancer]
  source     = "../../ces-module"

  # Configure CES installation options
  setup_chart_version          = var.setup_chart_version
  setup_chart_namespace        = var.setup_chart_namespace
  ces_fqdn                     = var.ces_fqdn != "" ? var.ces_fqdn : local.externalIP
  ces_admin_username           = var.ces_admin_username
  ces_admin_password           = var.ces_admin_password
  dogus                        = var.dogus
  resource_patches             = file(var.resource_patches_file)
  component_operator_chart     = var.component_operator_chart
  component_operator_crd_chart = var.component_operator_crd_chart
  components                   = var.components

  # Configure access for the registries. Passwords need to be base64-encoded.
  container_registry_secrets = var.container_registry_secrets
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password
  dogu_registry_endpoint     = var.dogu_registry_endpoint
  dogu_registry_url_schema   = var.dogu_registry_url_schema

  helm_registry_host         = var.helm_registry_host
  helm_registry_schema       = var.helm_registry_schema
  helm_registry_plain_http   = var.helm_registry_plain_http
  helm_registry_insecure_tls = var.helm_registry_insecure_tls
  helm_registry_username     = var.helm_registry_username
  helm_registry_password     = var.helm_registry_password
}
