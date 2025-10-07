# The local Closure converts input Parameter to usable template parameters
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

  ecosystem_core_default_config_image = {
    repository = split(":", var.ecosystem_core_default_config_image)[0]
    version = length(split(":", var.ecosystem_core_default_config_image)) == 2 ? split(":", var.ecosystem_core_default_config_image)[1] : "latest"
  }

  split_fqdn = split(".", var.ces_fqdn)
  # Top Level Domain extracted from fully qualified domain name. k3ces.local is used for development mode and empty fqdn.
  topLevelDomain = var.ces_fqdn != "" ? "${element(split(".", var.ces_fqdn), length(local.split_fqdn) - 2)}.${element(local.split_fqdn, length(local.split_fqdn) - 1)}" : "k3ces.local"

  globalConfig = [
    # Naming
    { key = "fqdn", value = var.ces_fqdn },
    { key = "domain", value = local.topLevelDomain },
    { key = "certificate/type", value = var.ces_certificate_path == null ? "selfsigned" : "external" },
    # This must be added to secret: ecosystem-certificate TODO
    #{ key = "certificate", value = var.ces_certificate_path != null ? replace(file(var.ces_certificate_path), "\n", "\\n") : ""},
    #{ key = "certificateKey", value = var.ces_certificate_key_path != null ? replace(file(var.ces_certificate_key_path), "\n", "\\n") : ""},
    { key = "k8s/use_internal_ip", value = "false"},
    { key = "internalIp", value = ""},

    { key = "password-policy/min_length", value: "1"} ,
    { key = "password-policy/must_contain_capital_letter", value: "false"},
    { key = "password-policy/must_contain_digit", value: "false" },
    { key = "password-policy/must_contain_lower_case_letter", value = "false" },
    { key = "password-policy/must_contain_special_character", value: "false" },

    # Admin
    { key = "admin_group", value = "cesAdmin"},
  ]

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
  depends_on = [kubernetes_namespace.ces_namespace]
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
    templatefile("${path.module}/values_ecosystem.yaml.tftpl",
      {
        "component_operator_image"                       = local.component_operator_image
        "components"                                     = local.components
        "ecosystem_core_default_config_image"            = local.ecosystem_core_default_config_image
        "ecosystem_core_defaultconfig_wait_timeout_secs" = var.ecosystem_core_defaultconfig_wait_timeout_minutes
      })
  ]
  depends_on = [
    helm_release.k8s_component_operator_crd,
    helm_release.k8s_blueprint_operator_crd,
    kubernetes_secret.dogu_registry,
    kubernetes_secret.ces_container_registries,
    kubernetes_secret.component_operator_helm_registry,
    kubernetes_config_map.component_operator_helm_repository
  ]
}

# The Blueprint is used to configure the system after the ecosystem-core has installed all
# necessary components, therefor it depends on the resource "ecosystem-core"
resource "kubectl_manifest" "blueprint" {
  yaml_body = templatefile(
    "${path.module}/blueprint.yaml.tftpl",
    {
      "dogus"         = local.parsedDogus
      "doguConfigs"   = local.doguConfigs
      "globalConfig"  = local.globalConfig
      "ces_namespace" = var.ces_namespace
    })
  depends_on = [
    helm_release.ecosystem-core,
    kubectl_manifest.ces_loadbalancer_ip_patch,
    kubernetes_secret.ecosystem_core_setup_credentials
  ]
}
