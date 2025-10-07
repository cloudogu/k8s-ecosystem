  component_operator_crd_chart                      = "k8s/k8s-component-operator-crd:1.10.1"
  blueprint_operator_crd_chart                      = "testing/k8s/k8s-blueprint-operator-crd:1.3.0-dev.1759235847"
  component_operator_image                          = "cloudogu/k8s-component-operator:1.10.1"
  ecosystem_core_default_config_image               = "cloudogu/ecosystem-core-default-config:0.2.2"

  ces_namespace = "ecosystem"
  # Configure CES installation options
  ecosystem_core_chart_namespace                    = "k8s"
  ecosystem_core_chart_version                      = "0.2.2"
  ecosystem_core_defaultconfig_wait_timeout_minutes = 30
  ecosystem_core_timeout                            = 1800

  components = {
    components = [
      { namespace = "ecosystem", name = "k8s-dogu-operator-crd", version = "2.9.0"},
      { namespace = "ecosystem", name = "k8s-dogu-operator", version = "3.13.0" },
      { namespace = "ecosystem", name = "k8s-service-discovery", version = "3.0.0" },
      { namespace = "ecosystem", name = "k8s-blueprint-operator-crd", version = "1.3.0", disabled = true },
      {
        namespace     = "ecosystem", name = "k8s-blueprint-operator", version = "2.8.0-dev.1758811397",
        helmNamespace = "testing/k8s",
        valuesObject = <<YAML
      healthConfig:
        components:
          required:
            - name: "k8s-dogu-operator"
            - name: "k8s-service-discovery"
YAML
      },
      { namespace = "ecosystem", name = "k8s-ces-gateway", version = "1.0.1" },
      { namespace = "ecosystem", name = "k8s-ces-assets", version = "1.0.1" },
      { namespace = "ecosystem", name = "k8s-ces-control", version = "1.7.1", disabled  = true },
      { namespace = "ecosystem", name = "k8s-debug-mode-operator-crd", version = "0.2.3" },
      { namespace = "ecosystem", name = "k8s-debug-mode-operator", version = "0.3.0" },
      { namespace = "ecosystem", name = "k8s-support-mode-operator-crd", version = "0.2.0", disabled  = true },
      { namespace = "ecosystem", name = "k8s-support-mode-operator", version = "0.3.0", disabled  = true },
    ]
    backup = {
      enabled = true
      components = [
        { namespace = "ecosystem", name = "k8s-backup-operator-crd", version = "1.6.0" },
        { namespace = "ecosystem", name = "k8s-backup-operator", version = "1.6.0" },
        { namespace = "ecosystem", name = "k8s-velero", version = "10.0.1-5" },
      ]
    }
    monitoring = {
      enabled = true
      components = [
        { namespace = "ecosystem", name = "k8s-prometheus", version = "75.3.5-3" },
        { namespace = "ecosystem", name = "k8s-minio", version = "2025.6.13-2" },
        { namespace = "ecosystem", name = "k8s-loki", version = "3.3.2-4" },
        { namespace = "ecosystem", name = "k8s-promtail", version = "2.9.1-9" },
        { namespace = "ecosystem", name = "k8s-alloy", version = "1.1.2-1" },
      ]
    }
  }

  # Helm credentials
  helm_registry_host         = "registry.cloudogu.com"
  helm_registry_schema       = "oci"
  helm_registry_username     = "helm-user"
  helm_registry_password     = "cm9ib3QkY29kZXItY2VzLW1uLXdvcmtzcGFjZTp2d0p2UzJOc2FiNldpQ0hjU1FBeERSd2JtR1NjM3F5aQ=="

  # Docker-Image Registry Credentials
  docker_registry_host       = "image_registry_url"
  docker_registry_username   = "image_registry_username"
  docker_registry_password   = "aW1hZ2VfcmVnaXN0cnlfcGFzc3dvcmQ="
  docker_registry_email      = "image_registry_username"


  # Dogu Registry Credentials
  dogu_registry_username     = "todo"
  dogu_registry_password     = "todo"

  # FQDN
  ces_fqdn  = "fqdn"

  // use coder username to be consistent with the classic-ces template
  ces_admin_username = "adminuser"
  // we don't use the coder user's email address because it might collide with that of an external user from keycloak
  ces_admin_email              = "admin@ces.invalid"
  ces_admin_password           = "adminpw"

  # Dogus
  dogus = [
      "official/ldap",
      "official/postfix",
      "k8s/nginx-static",
      "k8s/nginx-ingress",
      "official/cas",
    ]

  cas_oidc_config = {
    enabled             = false
    discovery_uri       = "/realms//.well-known/openid-configuration"
    client_id           = "some client"
    display_name        = "Cloudogu-Platform"
    optional            = false
    scopes = ["openid", "test1", "test2"]
    principal_attribute = "preferred_username"
    attribute_mapping   = "email:mail,family_name:surname,given_name:givenName,preferred_username:username,name:displayName,groups:externalGroups"
    allowed_groups = ["test1", "test2"]
    initial_admin_usernames = ["test1", "test2"]
  }
  cas_oidc_client_secret       = "oicdsecret"

  externalIP = "123.123.123.123"