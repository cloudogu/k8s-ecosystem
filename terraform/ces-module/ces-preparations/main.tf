locals {
  registry = "oci://registry.cloudogu.com/"

  _component_operator_crd_chart_parts = split("/", var.component_operator_crd_chart)

  // version is enforced by root module
  _component_operator_crd_chart_last = local._component_operator_crd_chart_parts[length(local._component_operator_crd_chart_parts) - 1]
  _component_operator_crd_chart_namever = split(":", local._component_operator_crd_chart_last)

  component_operator_crd_chart = {
    repository = join("/", slice(local._component_operator_crd_chart_parts, 0, length(local._component_operator_crd_chart_parts) - 1))
    name = local._component_operator_crd_chart_namever[0]
    version = local._component_operator_crd_chart_namever[1]
  }

  _blueprint_operator_crd_chart_parts = split("/", var.blueprint_operator_crd_chart)

  // version is enforced by root module
  _blueprint_operator_crd_chart_last = local._blueprint_operator_crd_chart_parts[length(local._blueprint_operator_crd_chart_parts) - 1]
  _blueprint_operator_crd_chart_namever = split(":", local._blueprint_operator_crd_chart_last)

  blueprint_operator_crd_chart = {
    repository = join("/", slice(local._blueprint_operator_crd_chart_parts, 0, length(local._blueprint_operator_crd_chart_parts) - 1))
    name = local._blueprint_operator_crd_chart_namever[0]
    version = local._blueprint_operator_crd_chart_namever[1]
  }

  decoded_helm_password = base64decode(var.helm_registry_password)

  # Basic-Auth as in shell script
  dogu_password_decoded = can(base64decode(var.dogu_registry_password)) ? base64decode(var.dogu_registry_password) : var.dogu_registry_password

  ext_ip     = try(trimspace(nonsensitive(var.externalIP)), "")
}

# Create the namespace for the ecosystem when create_namespace is true
resource "kubernetes_namespace" "ces_namespace" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.ces_namespace
  }
}

# In order to create component CRs, the corresponding CustomResourceDefinition (CRD) must already be registered in the cluster.
# Install the CRD using the published Helm chart from the OCI repository.
resource "helm_release" "k8s_component_operator_crd" {
  depends_on = [kubernetes_namespace.ces_namespace]
  name             = local.component_operator_crd_chart.name
  repository       = "${local.registry}${local.component_operator_crd_chart.repository}"
  chart            = local.component_operator_crd_chart.name
  version          = local.component_operator_crd_chart.version

  namespace        = var.ces_namespace
  create_namespace = false

  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300
}

# In order to create blueprint CRs, the corresponding CustomResourceDefinition (CRD) must already be registered in the cluster.
# Install the CRD using the published Helm chart from the OCI repository.
resource "helm_release" "k8s_blueprint_operator_crd" {
  depends_on = [kubernetes_namespace.ces_namespace]
  name             = local.blueprint_operator_crd_chart.name
  repository       = "${local.registry}${local.blueprint_operator_crd_chart.repository}"
  chart            = local.blueprint_operator_crd_chart.name
  version          = local.blueprint_operator_crd_chart.version

  namespace        = var.ces_namespace
  create_namespace = false

  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300
}

# This secret contains the access data for the **Dogu Registry**.
resource "kubernetes_secret" "dogu_registry" {
  depends_on = [kubernetes_namespace.ces_namespace]
  metadata {
    name      = "k8s-dogu-operator-dogu-registry"
    namespace = var.ces_namespace
  }

  type = "Opaque"

  data = {
    endpoint  = "https://dogu.cloudogu.com/api/v2/dogus"
    urlschema = "default"
    username  = var.dogu_registry_username
    password  = local.dogu_password_decoded
  }
}

# This secret contains the access data for the **container registry** in Docker registry format.
resource "kubernetes_secret" "ces_container_registries" {
  depends_on = [kubernetes_namespace.ces_namespace]
  metadata {
    name      = "ces-container-registries"
    namespace = var.ces_namespace
  }

  # kubectl create secret docker-registry
  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.docker_registry_host) = {
          username = var.docker_registry_username
          password = var.docker_registry_password
          email    = var.docker_registry_email
          auth     = base64encode("${var.docker_registry_username}:${base64decode(var.docker_registry_password)}")
        }
      }
    })
  }
}

# In addition to authentication, a ConfigMap and a secret must be created for the **Helm registry**.
resource "kubernetes_config_map" "component_operator_helm_repository" {
  depends_on = [kubernetes_namespace.ces_namespace]
  metadata {
    name      = "component-operator-helm-repository"
    namespace = var.ces_namespace
  }

  data = {
    endpoint    = "registry.cloudogu.com"
    schema      = "oci"
    plainHttp   = "false"
    insecureTls = "false"
  }
}
resource "kubernetes_secret" "component_operator_helm_registry" {
  depends_on = [kubernetes_namespace.ces_namespace]
  metadata {
    name      = "component-operator-helm-registry"
    namespace = var.ces_namespace
  }

  # kubectl create secret generic … --from-literal=config.json='…'
  type = "Opaque"

  data = {
    "config.json" = jsonencode({
      auths = {
        "registry.cloudogu.com" = {
          # echo -n "${USER}:${PASS}" | base64
          auth = base64encode("${var.helm_registry_username}:${local.decoded_helm_password}")
        }
      }
    })
  }
}