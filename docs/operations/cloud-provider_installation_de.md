# Installation in anderen Cloud-Providern

Die Installations-Skripte um das CES als POC in einem bereitgestellten Kubernetes-Cluster zu installieren sind im Ordner `externalcloud` zu finden.

## Vorbereitung

### .env.sh

Die Installation benötigt Angaben zum Kubectl-Context und den Dogu-Registrys. 
Diese können als Umgebungsvariablen über eine `.env.sh`-Datei im Installations-Ordner bereitgestellt werden.

```shell
# example .env.sh
export kube_context="ces-multinode"
export dogu_registry_username="username"
export dogu_registry_password="secret-password"
export dogu_registry_url="https://dogu.cloudogu.com/api/v2/dogus"
export image_registry_username="username"
export image_registry_password="secret-password"
export image_registry_email="test@test.de"
```

### setup.json

In der `setup.json` kann die Konfiguration für das CES angepasst werden.
Hier können u.a. der FQDN und der Admin-User konfiguriert werden.

### Cloud-Provider

Hinweise zu einzelnen Cloud-Providern sind hier zu finden:
- [GoogleCloud](cloud-provider_installation_google_cloud_de.md)
- [Azure AKS](cloud-provider_installation_azure_aks_de.md)
- [Plusserver](cloud-provider_installation_plusserver_de.md)

## Installation

Die Installation wird durch Ausführung der `install.sh`-Datei gestartet:

```shell
./install.sh
```

> Longhorn: Um Longhorn zu installieren, muss `./installLonghorn.sh` in der `install.sh` einkommentiert werden.
