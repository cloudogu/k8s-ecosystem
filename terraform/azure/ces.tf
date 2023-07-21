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

resource "kubectl_manifest" "ces-namespace" {
  apply_only = true
  yaml_body =  yamlencode({"apiVersion":"v1", "kind":"Namespace", "metadata":{"name": var.ecosystem_namespace}})
}

resource "kubernetes_secret" "k8s-dogu-operator-docker-registry" {
  metadata {
    name = "k8s-dogu-operator-docker-registry"
    namespace = var.ecosystem_namespace
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

  depends_on = [
    kubectl_manifest.ces-namespace
  ]
}

resource "kubernetes_secret" "k8s-dogu-operator-dogu-registry" {
  metadata {
    name = "k8s-dogu-operator-dogu-registry"
    namespace = var.ecosystem_namespace
  }

  type = "Opaque"

  data = {
    username = var.dogu_registry_username
    password = var.dogu_registry_password
    endpoint = var.dogu_registry_endpoint
  }

  depends_on = [
    kubectl_manifest.ces-namespace
  ]
}



resource "kubernetes_config_map" "k8s-ces-setup-json" {
  metadata {
    name = "k8s-ces-setup-json"
    namespace = var.ecosystem_namespace
  }

  data = {
    "setup.json" = templatefile(
      "${path.module}/setup.json.tftpl",
      {
        "admin_password" = var.ces_admin_password,
        "additional_dogus" = var.additional_dogus,
      }
    )
  }

  depends_on = [
    kubectl_manifest.ces-namespace
  ]
}

data "http" "setup_config_file" {
  url = "https://raw.githubusercontent.com/cloudogu/k8s-ces-setup/develop/k8s/k8s-ces-setup-config.yaml"
}

resource "kubectl_manifest" "setup_config" {
  override_namespace = var.ecosystem_namespace
  yaml_body = replace(data.http.setup_config_file.response_body, "/\\{\\{ .Namespace \\}\\}/", var.ecosystem_namespace)

  depends_on = [
    kubectl_manifest.ces-namespace
  ]
}

data "http" "setup_resources_file" {
  url = "https://raw.githubusercontent.com/cloudogu/k8s-ces-setup/develop/k8s/k8s-ces-setup.yaml"
}

data "kubectl_file_documents" "setup_resources" {
  content = replace(data.http.setup_resources_file.response_body, "/\\{\\{ .Namespace \\}\\}/", var.ecosystem_namespace)
}

resource "kubectl_manifest" "setup_resources_apply" {
  override_namespace = var.ecosystem_namespace
  for_each  = data.kubectl_file_documents.setup_resources.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.setup_config
  ]
}