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

   # Configure the access to the Kubernetes-Cluster 
   kubernetes_host                   = my_cluster.kube_config.host
   kubernetes_client_certificate     = base64decode(my_cluster.kube_config.client_certificate)
   kubernetes_client_key             = base64decode(my_cluster.kube_config.client_key)
   kubernetes_cluster_ca_certificate = base64decode(my_cluster.kube_config.cluster_ca_certificate)

   # Configure CES installation options
   setup_chart_version   = "1.0.0"
   setup_chart_namespace = "k8s"
   ces_fqdn              = "ces.local"
   ces_admin_password    = "test123"
   additional_dogus      = ["official/jenkins", "official/scm"]

   # Configure access for the registries. Passwords need to be base64-encoded.
   image_registry_url      = "registry.cloudogu.com"
   image_registry_username = "username"
   image_registry_password = "cGFzc3dvcmQ=" # Base64-encoded

   dogu_registry_username = "username"
   dogu_registry_password = "cGFzc3dvcmQ=" # Base64-encoded
   dogu_registry_endpoint = "https://dogu.cloudogu.com/api/v2/dogus"

   helm_registry_host     = "registry.cloudogu.com"
   helm_registry_schema   = "oci"
   helm_registry_username = "username"
   helm_registry_password = "cGFzc3dvcmQ=" # Base64-encoded
}
```

You can find a full list parameters with descriptions in [variables.tf](variables.tf).

Check out the [Azure AKS example](./examples/ces_azure_aks) for fully-working sample code for provisioning an AKS-Cluster on Azure and installing the CES.

Note the following parameters:

* `resource_patches_file`: Use this parameter to specify a `resource_patches`-file for applying patches to various resources during installation if needed.
   Further information can be found in the [k8s-ces-setup documentation] (https://github.com/cloudogu/k8s-ces-setup/blob/develop/docs/operations/configuration_guide_en.md#resource_patches)


## Notes for the setup helm release

Since the setup has to be run only once it will delete itself after the `terraform apply`.
To avoid a setup reapply in subsequently `terraform apply` you can configure a kubernetes resource to identify that the setup already run.
Use the variable `is_setup_applied_matching_resource`. The dogu custom resource definition is used as the default for this.

