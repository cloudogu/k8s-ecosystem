provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }

  registry {
    url      = var.helm_registry_url
    username = var.helm_registry_username
    password = var.helm_registry_password
  }
}

resource "helm_release" "k8s-ces-setup" {
  name       = "k8s-ces-setup"
  repository = "${var.helm_registry_url}/${var.setup_chart_namespace}"
  chart      = "k8s-ces-setup"
  version    = var.setup_chart_version

  namespace        = var.ecosystem_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml.tftpl",
      {
        "dogu_registry_endpoint"   = var.dogu_registry_endpoint
        "dogu_registry_username"   = var.dogu_registry_username
        "dogu_registry_password"   = var.dogu_registry_password
        "docker_registry_url"      = var.image_registry_url
        "docker_registry_username" = var.image_registry_username
        "docker_registry_password" = var.image_registry_password
        "helm_registry_url"        = var.helm_registry_url
        "helm_registry_username"   = var.helm_registry_username
        "helm_registry_password"   = var.helm_registry_password
        "setup_json"               = yamlencode(templatefile(
          "${path.module}/setup.json.tftpl",
          {
            "admin_password"   = var.ces_admin_password,
            "additional_dogus" = var.additional_dogus,
          }
        ))
      })
  ]
}
