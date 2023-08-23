# Provisioning with Terraform in Azure

CES Multinode can be provisioned in Azure with the help of Terraform.
This involves first creating an Azure AKS cluster and then installing CES-Multinode in it.

## Preparation

The required Terraform files can be found in the folder `terraform/azure`.

### terraform.tfvars

The `terraform.tfvars` file contains the values for the variables used for provisioning.
All variables for which no values are specified in `terraform.tfvars` must be specified when running Terraform
must be specified.

As a template, the file `terraform.tfvars.template` can be copied and renamed to `terraform.tfvars`.

An example `terraform.tfvars` might look like this:

```
azure_appId = "aaaaaa"
azure_password = "pppppp"
image_registry_username = "user".
image_registry_password = "password
image_registry_email = "mail@foo.bar"
dogu_registry_username = "user
dogu_registry_password = "password
dogu_registry_endpoint = "https://dogu.cloudogu.com/api/v2/dogus"
aks_cluster_name="my-ces"
aks_node_count = 3
aks_vm_size = "Standard_D2_v2"
ces_admin_password="password"
additional_dogus = ["official/jenkins", "official/scm"]
```

### setup.json.tftpl

In the `setup.json.tftpl` the configuration for the CES can be adjusted.
Some values are already populated by terraform variables.

### values.yaml.tftpl

In the `values.yaml.tftpl` the configuration for the setup Helm-Chart can be adjusted.
Some values are already populated by terraform variables.

### Create Azure Service Principal

In order for Terraform to manage resources at Azure, a "Service Principal" is needed to grant access.
A service principal can be created using the Azure CLI:

```shell
az ad sp create-for-rbac --skip-assignment
```

The output of the command looks like this:

```json
{
  "appId": "72c7cffa-2bf0-4025-999c-898054066080",
  "displayName": "azure-cli-2023-07-18-12-51-07",
  "password": "xxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "24458c45-b187-458e-8b08-c55d017dd2c2"
}
```

The data must be transferred to the variables `azure_appId` and `azure_password`.

## Variables

The following variables are available

| name                    | description                                                           | default value |
|-------------------------|-----------------------------------------------------------------------|---------------|
| azure_appId             | Azure Kubernetes Service Cluster service principal                    | -             |
| azure_password          | Azure Kubernetes Service Cluster password                             | -             |
| aks_cluster_name        | The name of the Azure AKS Cluster                                     | -             |
| aks_node_count          | The number of nodes to create                                         | 2             |
| aks_vm_size             | The size of the Virtual Machine fo the nodes, such as Standard_DS2_v2 | Standard_B2s  |
| ecosystem_namespace     | The namespace for the CES                                             | ecosystem     |
| image_registry_url      | The endpoint for the docker-image-registry                            | -             |
| image_registry_username | The username for the docker-image-registry                            | -             |
| image_registry_password | The password for the docker-image-registry                            | -             |
| dogu_registry_username  | The username for the dogu-registry                                    | -             |
| dogu_registry_password  | The password for the dogu-registry                                    | -             |
| dogu_registry_endpoint  | The endpoint for the dogu-registry                                    | -             |
| helm_registry_url       | The endpoint for the helm-registry                                    | -             |
| helm_registry_username  | The username for the helm-registry                                    | -             |
| helm_registry_password  | The password for the helm-registry                                    | -             |
| setup_chart_version     | The chart version from k8s-ces-setup to install                       |               |
| setup_chart_namespace   | The repository of the k8s-ces-setup chart                             |               |
| ces_admin_password      | The CES admin password                                                | -             |
| ces_admin_password      | The CES admin password                                                | -             |
| additional_dogus        | A list of additional Dogus to install                                 | []            |

## Provisioning

First you have to initialize Terraform:

```shell
terraform init
```

Then the installation can be started:

```shell
terraform apply
```

## Delete

The cluster and all associated resources can be deleted again with Terraform:

```shell
terraform destroy
```

## Rework

### CAS

Additional dogus installed after setup may require the `CAS` to be restarted in order for login for the dogus is
possible.
To do this, simply delete the `CAS` pod.