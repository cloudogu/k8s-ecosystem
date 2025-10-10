locals {
  _component_operator_crd_chart_parts = split("/", var.component_operator_crd_chart)
  component_operator_crd_chart = {
    repository = join("/", slice(local._component_operator_crd_chart_parts, 0, length(local._component_operator_crd_chart_parts) - 1))
    name = split(":", local._component_operator_crd_chart_parts[length(local._component_operator_crd_chart_parts) - 1])[0]
    version = length(split(":", var.component_operator_crd_chart)) == 2 ? split(":", var.component_operator_crd_chart)[1] : "1.10.1"
  }

  _blueprint_operator_crd_chart_parts = split("/", var.blueprint_operator_crd_chart)
  blueprint_operator_crd_chart = {
    repository = join("/", slice(local._blueprint_operator_crd_chart_parts, 0, length(local._blueprint_operator_crd_chart_parts) - 1))
    name = split(":", local._blueprint_operator_crd_chart_parts[length(local._blueprint_operator_crd_chart_parts) - 1])[0]
    version = length(split(":", var.blueprint_operator_crd_chart)) == 2 ? split(":", var.blueprint_operator_crd_chart)[1] : "1.4.0"
  }

  component_operator_image = {
    repository = split(":", var.component_operator_image)[0]
    version = length(split(":", var.component_operator_image)) == 2 ? split(":", var.component_operator_image)[1] : "latest"
  }

  decoded_helm_password = base64decode(var.helm_registry_password)

  # Basic-Auth wie im Shellscript (Passwort ggf. base64-decoden)
  dogu_password_decoded = can(base64decode(var.dogu_registry_password)) ? base64decode(var.dogu_registry_password) : var.dogu_registry_password
}

# In order to create component CRs, the corresponding CustomResourceDefinition (CRD) must already be registered in the cluster.
# Install the CRD using the published Helm chart from the OCI repository.
resource "helm_release" "k8s_component_operator_crd" {
  name             = local.component_operator_crd_chart.name
  repository       = "oci://registry.cloudogu.com/${local.component_operator_crd_chart.repository}"
  chart            = local.component_operator_crd_chart.name
  version          = local.component_operator_crd_chart.version

  namespace        = var.ces_namespace
  create_namespace = false     # true setzen, wenn du die Ressource oben weglässt

  # Helm-Flags analog zum CLI-Aufruf
  atomic           = true      # rollt bei Fehlern zurück
  cleanup_on_fail  = true
  timeout          = 300
}

# This is needed due to terraform pre-flight checks.
# The Blueprint-CRD must be available before the ecosystem-core can install it.
# In production the ecosystem-core would install the blueprint crd
resource "helm_release" "k8s_blueprint_operator_crd" {
  name             = local.blueprint_operator_crd_chart.name
  repository       = "oci://registry.cloudogu.com/${local.blueprint_operator_crd_chart.repository}"
  chart            = local.blueprint_operator_crd_chart.name
  version          = local.blueprint_operator_crd_chart.version

  namespace        = var.ces_namespace
  create_namespace = false     # true setzen, wenn du die Ressource oben weglässt

  # Helm-Flags analog zum CLI-Aufruf
  atomic           = true      # rollt bei Fehlern zurück
  cleanup_on_fail  = true
  timeout          = 300
}

# This secret contains the access data for the **Dogu Registry**.
resource "kubernetes_secret" "dogu_registry" {
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
  metadata {
    name      = "ces-container-registries"
    namespace = var.ces_namespace
  }

  # Entspricht: kubectl create secret docker-registry
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
  metadata {
    name      = "component-operator-helm-registry"
    namespace = var.ces_namespace
  }

  # entspricht: kubectl create secret generic … --from-literal=config.json='…'
  type = "Opaque"

  data = {
    "config.json" = jsonencode({
      auths = {
        "registry.cloudogu.com" = {
          # entspricht: echo -n "${USER}:${PASS}" | base64
          auth = base64encode("${var.helm_registry_username}:${local.decoded_helm_password}")
        }
      }
    })
  }
}