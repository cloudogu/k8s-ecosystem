locals {
  component_operator_image = {
    repository = split(":", var.component_operator_image)[0]
    version = length(split(":", var.component_operator_image)) == 2 ? split(":", var.component_operator_image)[1] : "latest"
  }

  compcomponents = [
    for comp in var.components.components : merge(
      comp,
        comp.name == "k8s-ces-assets" ? { valuesObject = "      nginx:\n        manager:\n          config:\n            defaultDogu: \"${var.default_dogu}\"" } : {}
    )
  ]

  components = {
    components = local.compcomponents
    backup = var.components.backup
    monitoring = var.components.monitoring
  }
}


# This secret contains the access data for the **Dogu Registry**.
resource "kubernetes_secret" "ecosystem_core_setup_credentials" {
  metadata {
    name      = "ecosystem-core-setup-credentials"
    namespace = var.ces_namespace
  }

  type = "Opaque"

  data = {
    cas_oidc_client_secret  = var.cas_oidc_client_secret,
    ldap_admin_password = var.ces_admin_password
  }
}

# This installs the ecosystem-core component, the values are defined by templating the values.yaml file.
# This resource depends on the CRD's, Secrets and the Configmap defined in this file above.
resource "helm_release" "ecosystem-core" {
  name       = "ecosystem-core"
  repository = "${var.helm_registry_schema}://${var.helm_registry_host}/${var.ecosystem_core_chart_namespace}"
  chart      = "ecosystem-core"
  version    = var.ecosystem_core_chart_version
  timeout    = var.ecosystem_core_timeout

  namespace        = var.ces_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml.tftpl",
      {
        "component_operator_image"                       = local.component_operator_image
        "components"                                     = local.components
      })
  ]
  depends_on = [
    kubernetes_secret.ecosystem_core_setup_credentials,
  ]
}