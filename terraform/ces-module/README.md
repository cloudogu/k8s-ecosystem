# Terraform CES Module

This folder contains a [Terraform](https://www.terraform.io/) module to deploy the Cloudogu Ecosystem (CES) in a Kubernetes-Cluster.
This module is designed to be used in addition to other Terraform-Providers provisioning the Kubernetes-Cluster.

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "ces" {
  # update this to the URL and version you want to use
  source = "github.com/cloudogu/k8s-ecosystem/terraform/ces-module"

  component_operator_crd_chart                      = "k8s/k8s-component-operator-crd:1.10.1"
  blueprint_operator_crd_chart                      = "k8s/k8s-blueprint-operator-crd:1.3.0"
  component_operator_image                          = "cloudogu/k8s-component-operator:1.10.1"
   
  ces_namespace = "ecosystem"

  # Configure CES installation options
  ecosystem_core_chart_namespace                    = "k8s"
  ecosystem_core_chart_version                      = "1.0.0"
  ecosystem_core_defaultconfig_wait_timeout_minutes = 30
  ecosystem_core_timeout                            = 1800 

  # Configure CES installation options
  ces_fqdn              = "ces.local"
  ces_admin_password    = "test123"

  # thi sis optional - it will replace the actual external ip of the ces-loadbalancer
  externalIP = "127.0.0.1"

  components = {
    components = [
      { namespace = "ecosystem", name = "k8s-dogu-operator-crd", version = "2.9.0" },
      { namespace = "ecosystem", name = "k8s-dogu-operator", version = "3.13.0" },
      { namespace = "ecosystem", name = "k8s-service-discovery", version = "3.0.0" },
      # disable this component, because the blueprint-crd needs to be installed prior to the blueprint-terraform step 
      { namespace = "ecosystem", name = "k8s-blueprint-operator-crd", version = "1.3.0", disabled = true },
      { namespace = "ecosystem", name = "k8s-blueprint-operator", version = "3.0.0" },
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
   
  dogus                 = [
    "official/ldap",
    "official/postfix",
    "official/cas",
    "official/jenkins",
    "official/scm"
  ]

  # Configure access for the registries. Passwords need to be base64-encoded.
   # Configure the access to the Kubernetes-Cluster 
  kubernetes_host                   = my_cluster.kube_config.host
  kubernetes_client_certificate     = base64decode(my_cluster.kube_config.client_certificate)
  kubernetes_client_key             = base64decode(my_cluster.kube_config.client_key)
  kubernetes_cluster_ca_certificate = base64decode(my_cluster.kube_config.cluster_ca_certificate)

  dogu_registry_username = "username"
  dogu_registry_password = "cGFzc3dvcmQ=" # Base64-encoded
  
  helm_registry_host     = "registry.cloudogu.com"
  helm_registry_schema   = "oci"
  helm_registry_username = "username"
  helm_registry_password = "cGFzc3dvcmQ=" # Base64-encoded
   
  # Docker-Image Registry Credentials
  docker_registry_host       = "registry.cloudogu.com"
  docker_registry_username   = "username"
  docker_registry_password   = "cGFzc3dvcmQ=" # Base64-encoded
  docker_registry_email      = "user@domain.com"
}
```

You can find a full list parameters with descriptions in [variables.tf](variables.tf).

Check out the [Azure AKS example](../examples/ces_azure_aks) or [Google GKE example](../examples/ces_google_gke) for fully-working sample code for provisioning a Cluster on Azure or Google and installing the CES.

## Notes for the setup helm release

Since the setup has to be run only once it will delete itself after the `terraform apply`.
To avoid a setup reapply in subsequent `terraform apply` executions you can configure a kubernetes resource to identify that the setup has already run.
Use the variable `is_setup_applied_matching_resource`. The dogu custom resource definition is used as the default for this.

The mechanism uses the kubernetes provider identifying the resource.
On an initial `terraform apply` there is no cluster available so the count of the helm release can't be determined.
Therefore you have to run terraform with the cluster module as target first: `terraform apply -target=module.<moduleName>`.
After that you can execute `terraform apply` regularly.

