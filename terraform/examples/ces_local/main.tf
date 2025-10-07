terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2"
    }
  }

  required_version = ">= 1.7.0"
}

provider kubernetes {
  config_path = var.local_kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = var.local_kube_config_path
  }

  registry {
    url      = "${var.helm_registry_schema}://${var.helm_registry_host}"
    username = var.helm_registry_username
    password = base64decode(var.helm_registry_password)
  }
}

module "ces" {
  source = "../../ces-module"

  # Configure CES installation options
  component_operator_crd_chart        = var.component_operator_crd_chart
  blueprint_operator_crd_chart        = var.blueprint_operator_crd_chart
  component_operator_image            = var.component_operator_image
  ecosystem_core_default_config_image = var.ecosystem_core_default_config_image

  ces_fqdn                            = var.ces_fqdn
  ces_admin_username                  = var.ces_admin_username
  ces_admin_password                  = var.ces_admin_password
  dogus                               = var.dogus

  components                          = var.components

  # TODO
  # resource_patches             = file(var.resource_patches_file)

  dogu_registry_username   = var.dogu_registry_username
  dogu_registry_password   = var.dogu_registry_password

  docker_registry_host       = var.docker_registry_host
  docker_registry_username   = var.docker_registry_username
  docker_registry_password   = var.docker_registry_password
  docker_registry_email      = var.docker_registry_email

  helm_registry_host         = var.helm_registry_host
  helm_registry_schema       = var.helm_registry_schema
  helm_registry_username     = var.helm_registry_username
  helm_registry_password     = var.helm_registry_password
}