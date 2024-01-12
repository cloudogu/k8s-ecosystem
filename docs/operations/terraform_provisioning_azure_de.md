# Provisionierung mit Terraform in Azure

CES-Multinode kann mithilfe von Terraform in Azure provisioniert werden.
Dabei wird zunächst ein Azure AKS Cluster erstellt und in diesem anschließend CES-Multinode installiert.

## Terraform-Modul

Das benötigte Terraform-Modul ist im Ordner [`terraform/ces-module`](../../terraform/ces-module) zu finden.

### Beispiel

Ein Beispiel zur Installation in Azure ist in [`examples/ces_azure_aks`](../../terraform/ces-module/examples/ces_azure_aks) zu finden.
Dort müssen einige Variablen für die Erstellung des AKS-Cluster und die Installation des CES angegeben werden:

#### lokale Variablen
* `azure_client_id`: Die ID des Azure ServicePrincipal (siehe [unten](#azure-service-principal-erstellen))
* `azure_client_secret`: Das Passwort des Azure ServicePrincipal (siehe [unten](#azure-service-principal-erstellen))

#### CES-Modul Variablen
Die Konfiguration des Terraform-CES-Moduls ist in dessen [Dokumentation](../../terraform/ces-module/README.md) beschrieben.

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

Die Daten müssen in die Variablen `azure_client_id` und `azure_client_secret` übernommen werden.


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