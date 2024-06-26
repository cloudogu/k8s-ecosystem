# Provisioning with Terraform in Azure

CES Multinode can be provisioned in Azure with the help of Terraform.
This involves first creating an Azure AKS cluster and then installing CES-Multinode in it.

## Terraform-Modul

The required Terraform module can be found in the folder [`terraform/ces-module`](../../terraform/ces-module).

### Example

An example of the installation in Azure can be found in [`examples/ces_azure_aks`](../../terraform/ces-module/examples/ces_azure_aks).
Some variables for the creation of the AKS cluster and the installation of the CES must be specified there:

#### local variables
* `azure_client_id`: The ID of the Azure ServicePrincipal (see [below](#create-azure-service-principal))
* `azure_client_secret`: The password of the Azure ServicePrincipal (see [below](#create-azure-service-principal))

#### CES module variables
The configuration of the Terraform CES module is described in its [documentation](../../terraform/ces-module/README.md).

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

Additional dogus installed after setup may require the `CAS` to be restarted in order for login for the dogus is possible.
To do this, simply delete the `CAS` pod.