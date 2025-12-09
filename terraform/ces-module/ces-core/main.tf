locals {}

# This secret contains the access data for the **Dogu Registry**.
resource "kubernetes_secret" "ecosystem_core_setup_credentials" {
  metadata {
    name      = "ecosystem-core-setup-credentials"
    namespace = var.ces_namespace
  }

  type = "Opaque"

  data = {
    cas_oidc_client_secret  = var.cas_oidc_client_secret,
    ldap_admin_password     = var.ces_admin_password
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

  values = [
    templatefile("${path.module}/values.yaml.tftpl",
      {
        "components"                                     = var.components
      })
  ]

  # wait for default-config-job to be completed
  wait_for_jobs = true

  depends_on = [
    kubernetes_secret.ecosystem_core_setup_credentials,
  ]
}