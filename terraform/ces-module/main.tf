terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    kubectl = {
      // The official kubectl provider from hashicorp can't be used because it requires crd read permissions on generic cr apply.
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

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

  parsedDogus = [
    for dogu in var.dogus :
    {
      name            = split(":", dogu)[0]
      version         = length(split(":", dogu)) == 2 ? split(":", dogu)[1] : "latest"
    }
  ]

  doguConfigs = {
    ldap = [
      { key = "admin_username", value = var.ces_admin_username },
      { key = "admin_mail", value = var.ces_admin_email },
      { key = "admin_member", value = "true" },

      { key: "admin_password", secretRef:  { key: "ldap_admin_password", name: "ecosystem-core-setup-credentials" }, sensitive: true}
    ],
    postifx = [
      { key = "relayhost", value = "foobar" }
    ],
    cas = [
      { key = "oidc/enabled", value = var.cas_oidc_config.enabled },
      { key = "oidc/discovery_uri", value = var.cas_oidc_config.discovery_uri },
      { key = "oidc/client_id", value = var.cas_oidc_config.client_id },
      { key = "oidc/display_name", value = var.cas_oidc_config.display_name },
      { key = "oidc/optional", value = var.cas_oidc_config.optional },
      { key = "oidc/scopes", value = var.cas_oidc_config.scopes },
      { key = "oidc/principal_attribute", value = var.cas_oidc_config.principal_attribute },
      { key = "oidc/attribute_mapping", value = var.cas_oidc_config.attribute_mapping },
      { key = "oidc/allowed_groups", value = var.cas_oidc_config.allowed_groups },
      { key = "oidc/initial_admin_usernames", value = var.cas_oidc_config.initial_admin_usernames },

      { key: "oidc/client_secret", secretRef:  { key: "cas_oidc_client_secret", name: "ecosystem-core-setup-credentials" }, sensitive: true}
    ]
  }

  split_fqdn = split(".", var.ces_fqdn)
  # Top Level Domain extracted from fully qualified domain name. k3ces.local is used for development mode and empty fqdn.
  topLevelDomain = var.ces_fqdn != "" ? "${element(split(".", var.ces_fqdn), length(local.split_fqdn) - 2)}.${element(local.split_fqdn, length(local.split_fqdn) - 1)}" : "k3ces.local"

  globalConfig = [
    # Naming
    { key = "fqdn", value = var.ces_fqdn },
    { key = "domain", value = local.topLevelDomain },
    { key = "certificate/type", value = var.ces_certificate_path == null ? "selfsigned" : "external" },
    { key = "certificate", value = var.ces_certificate_path != null ? replace(file(var.ces_certificate_path), "\n", "\\n") : ""},
    { key = "certificateKey", value = var.ces_certificate_key_path != null ? replace(file(var.ces_certificate_key_path), "\n", "\\n") : ""},
    { key = "k8s/use_internal_ip", value = "false"},
    { key = "internalIp", value = ""},

    # Admin
    { key = "admin_group", value = "cesAdmin"},
  ]

  compcomponents = [
    for comp in var.components.components : merge(
      comp,
        comp.name == "k8s-ces-assets" ? { valueObject = {
        nginx = {
          manager = {
            config = {
              defaultDogu = var.default_dogu
            }
          }
        } } } : {}
    )
  ]

  components = {
    components = local.compcomponents
    backup = var.components.backup
    monitoring = var.components.monitoring
  }

  decoded_helm_password = base64decode("${var.helm_registry_password}")
}

resource "kubernetes_namespace" "ecosystem_core_chart_namespace" {
  metadata { name = var.ecosystem_core_chart_namespace } # "ecosystem"
}

resource "kubernetes_namespace" "ces_namespace" {
  metadata { name = var.ces_namespace } # "ecosystem"
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
  depends_on = [kubernetes_namespace.ecosystem_core_chart_namespace]
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
  depends_on = [kubernetes_namespace.ecosystem_core_chart_namespace]
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
    password  = var.dogu_registry_password
  }
  depends_on = [kubernetes_namespace.ces_namespace]
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
          auth     = base64encode("${var.docker_registry_username}:${var.docker_registry_password}")
        }
      }
    })
  }
  depends_on = [kubernetes_namespace.ces_namespace]
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
  depends_on = [kubernetes_namespace.ces_namespace]
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
  depends_on = [kubernetes_namespace.ces_namespace]
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
      "dogus"        = local.parsedDogus
      "doguConfigs"  = local.doguConfigs
      "globalConfig" = local.globalConfig
    })
  depends_on = [
    helm_release.ecosystem-core,
    kubernetes_secret.ecosystem_core_setup_credentials
  ]
}
