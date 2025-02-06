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
  }
}

provider "kubectl" {
  alias       = "kubectl_garden"
  config_path = var.gardener_kube_config_path
}

locals {
  shoot_kube_config_path = "${module.plusserver.shoot_name}_kubeconfig.yaml"
}

provider "helm" {
  alias = "helm_shoot"

  kubernetes {
    config_path = local.shoot_kube_config_path
  }

  registry {
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

module "plusserver" {
  source                    = "../../plusserver"
  gardener_kube_config_path = var.gardener_kube_config_path
  garden_namespace          = var.garden_namespace
  project_id                = var.project_id
  secret_binding_name       = var.secret_binding_name
  networking_type           = var.networking_type
}

provider "kubernetes" {
  alias       = "kubernetes_shoot"
  config_path = local.shoot_kube_config_path
}



resource "null_resource" "getShootKubeConfig" {
  provisioner "local-exec" {
    command = "./getShootKubeConfig.sh ${var.garden_namespace} ${module.plusserver.shoot_name} ${var.gardener_kube_config_path} ${local.shoot_kube_config_path}"
  }

  // Always trigger this resource to ensure kube config is always valid.
  triggers = {
    timestamp = timestamp()
  }

  depends_on = [module.plusserver]
}


// Create namespace without putting it into terraform state because it would block terraform destroy due to finalizers.
resource "null_resource" "create_namespace_ecosystem" {
  provisioner "local-exec" {
    command = "./createNamespace.sh ${local.shoot_kube_config_path} ecosystem"
  }

  depends_on = [null_resource.getShootKubeConfig]
}


// In general the service-discovery would create this loadbalancer service.
// Updating the service-discovery maybe requires updating this resource.
resource "kubernetes_service_v1" "ces-loadbalancer" {
  metadata {
    name        = "ces-loadbalancer"
    annotations = {
      // TODO Change to true if it works. And on destroy we have to change this to false again to release the ip.
      "loadbalancer.openstack.org/keep-floatingip" : "false"
    }
    labels = {
      "app" : "ces"
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
}

locals {
  // Yep, this works...
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
