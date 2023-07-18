provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "kubectl" {
  load_config_file       = false
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "ecosystem" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "k8s-dogu-operator-docker-registry" {
  metadata {
    name = "k8s-dogu-operator-docker-registry"
    namespace = var.namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.cloudogu.com" = {
          "username" = var.image_registry_username
          "password" = var.image_registry_password
          "email"    = var.image_registry_email
          "auth"     = base64encode("${var.image_registry_username}:${var.image_registry_password}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "k8s-dogu-operator-dogu-registry" {
  metadata {
    name = "k8s-dogu-operator-dogu-registry"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    username = var.dogu_registry_username
    password = var.dogu_registry_password
    endpoint = var.dogu_registry_endpoint
  }
}



resource "kubernetes_config_map" "k8s-ces-setup-json" {
  metadata {
    name = "k8s-ces-setup-json"
    namespace = var.namespace
  }

  data = {
    "setup.json" = templatefile(
      "${path.module}/setup.json.tftpl",
      {
        "admin_password" = var.ces_admin_password
      }
    )
  }
}

data "http" "setup_config" {
  url = "https://raw.githubusercontent.com/cloudogu/k8s-ces-setup/develop/k8s/k8s-ces-setup-config.yaml"
}

resource "kubectl_manifest" "setup_config_map" {
  override_namespace = var.namespace
  yaml_body = replace(data.http.setup_config.response_body, "/\\{\\{ .Namespace \\}\\}/", var.namespace)
}

data "http" "setup_resources_file" {
  url = "https://raw.githubusercontent.com/cloudogu/k8s-ces-setup/develop/k8s/k8s-ces-setup.yaml"
}

data "kubectl_file_documents" "setup_resources" {
  content = replace(data.http.setup_resources_file.response_body, "/\\{\\{ .Namespace \\}\\}/", var.namespace)
}

resource "kubectl_manifest" "setup_resources_apply" {
  override_namespace = var.namespace
  for_each  = data.kubectl_file_documents.setup_resources.manifests
  yaml_body = each.value
}