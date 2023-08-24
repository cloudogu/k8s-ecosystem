# Provisionierung mit Terraform in Azure

CES-Multinode kann mithilfe von Terraform in Azure provisioniert werden.
Dabei wird zunächst ein Azure AKS Cluster erstellt und in diesem anschließend CES-Multinode installiert.

## Vorbereitung

Die benötigten Terraform-Dateien sind im Ordner `terraform/azure` zu finden.

### terraform.tfvars

Die Datei `terraform.tfvars` enthält die Werte für die Variablen, die zum Provisionieren verwendet werden.
Alle Variablen für die keine Werte in der `terraform.tfvars` angegeben sind, müssen bei Ausführung von Terraform
angegeben werden.

Als Vorlage kann die Datei `terraform.tfvars.template` kopiert und in `terraform.tfvars` umbenannt werden.

Eine Beispiel `terraform.tfvars` könnte wie folgt aussehen:

```
azure_appId    = "aaaaaa"
azure_password = "pppppp"
image_registry_username = "user"
image_registry_password = "password"
image_registry_email = "mail@foo.bar"
dogu_registry_username = "user"
dogu_registry_password = "password"
dogu_registry_endpoint = "https://dogu.cloudogu.com/api/v2/dogus"
aks_cluster_name="my-ces"
aks_node_count = 3
aks_vm_size = "Standard_D2_v2"
ces_admin_password="password"
additional_dogus = ["official/jenkins", "official/scm"]
```

### setup.json.tftpl

In der `setup.json.tftpl` kann die Konfiguration für das CES angepasst werden.
Einige Werte werden bereits durch Terraform-Variablen befüllt.

### values.yaml.tftpl

In der `values.yaml.tftpl` kann die Konfiguration das Helm-Chart angegeben werden.
Einige Werte werden bereits durch Terraform-Variablen befüllt.

### Azure Service Principal erstellen

Damit Terraform bei Azure Ressourcen verwalten kann, wird ein "Service Principal" benötigt, das den Zugriff gewährt.
Ein Service Principal kann mit der Azure CLI erstellt werden:

```shell
az ad sp create-for-rbac --skip-assignment
```

Der Output des Befehls sieht wie folgt aus:

```json
{
  "appId": "72c7cffa-2bf0-4025-999c-898054066080",
  "displayName": "azure-cli-2023-07-18-12-51-07",
  "password": "xxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "24458c45-b187-458e-8b08-c55d017dd2c2"
}
```

Die Daten müssen in die Variablen `azure_appId` und `azure_password` übernommen werden.

## Variablen

Folgende Variablen sind vorhanden

| Name                    | Beschreibung                                                          | Default-Wert |
|-------------------------|-----------------------------------------------------------------------|--------------|
| azure_appId             | Azure Kubernetes Service Cluster service principal                    | -            |
| azure_password          | Azure Kubernetes Service Cluster password                             | -            |
| aks_cluster_name        | The name of the Azure AKS Cluster                                     | -            |
| aks_node_count          | The number of nodes to create                                         | 2            |
| aks_vm_size             | The size of the Virtual Machine fo the nodes, such as Standard_DS2_v2 | Standard_B2s |
| ecosystem_namespace     | The namespace for the CES                                             | ecosystem    |
| image_registry_url      | The endpoint for the docker-image-registry                            | -            |
| image_registry_username | The username for the docker-image-registry                            | -            |
| image_registry_password | The password for the docker-image-registry                            | -            |
| dogu_registry_username  | The username for the dogu-registry                                    | -            |
| dogu_registry_password  | The password for the dogu-registry                                    | -            |
| dogu_registry_endpoint  | The endpoint for the dogu-registry                                    | -            |
| helm_registry_url       | The endpoint for the helm-registry                                    | -            |
| helm_registry_username  | The username for the helm-registry                                    | -            |
| helm_registry_password  | The password for the helm-registry                                    | -            |
| setup_chart_version     | The chart version from k8s-ces-setup to install                       |              |
| setup_chart_namespace   | The repository of the k8s-ces-setup chart                             |              |
| ces_admin_password      | The CES admin password                                                | -            |
| additional_dogus        | A list of additional Dogus to install                                 | []           |

## Provisionierung

Zu nächst muss Terraform initialisiert werden:

```shell
terraform init
```

Anschließend kann die Installation gestartet werden:

```shell
terraform apply
```

## Löschen

Der Cluster und alle zugehörigen Ressourcen können mit Terraform wieder gelöscht werden:

```shell
terraform destroy
```

## Nacharbeiten

### CAS

Zusätzliche Dogus, die nach dem Setup installiert werden, erfordern evtl. dass der `CAS` neugestartet werden muss, damit
ein Login für die Dogus möglich ist.
Dazu kann der `CAS`-Pod einfach gelöscht werden.