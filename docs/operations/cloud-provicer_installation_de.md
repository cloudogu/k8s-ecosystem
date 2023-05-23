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
- [GoogleCloud](cloud-provicer_installation_google_cloud_de.md)
- [Azure AKS](cloud-provicer_installation_azure_aks_de.md)
- [Plusserver](cloud-provicer_installation_plusserver_de.md)

## Installation

Die Installation wird durch Ausführung der `install.sh`-Datei gestartet:

```shell
./install.sh
```

> Longhorn: Um Longhorn zu installieren, muss `./installLonghorn.sh` in der `install.sh` einkommentiert werden.

## Nacharbeiten

### FQDN-Änderung

Wenn als FQDN eine IP-Adresse verwendet wird und diese vor der Installation nicht korrekt in der `setup.json` angegeben wurde, muss diese nachträglich geändert werden.
Wenn dem LoadBalancer-Service `nginx-ingress-exposed-443` eine IP zugewiesen wurde, kann dazu das Skript `syncFQDN.sh` ausgeführt werden.

- Es liest die externe IP aus dem k8s-Service
- Im "etcd-client"-Deployment wird die IP als FQDN gesetzt `etcdctl set /config/_global/fqdn <IP>`
- Anschließend wird das selbst-signierte Zertifikat von der `k8s-service-discovery` automatisch neu erstellt
- Zuletzt werden alle Pods der Dogus neu gestartet

### Postgresql

Der Postgres-Container hat eine andere Routing-Tabelle. Das Dogu verarbeitet nur die genaue. 0.0.0.0 wir ignoriert.
Zur Behebung muss das Skript `fixPostgresql.sh` ausgeführt werden. Inhalte des Skripts:

- Bearbeitung der Subnetzmaske von `/var/lib/postgresql/pg_hba.conf` im Container-Netzwerk. Zum Beispiel von `32` auf `16`:
```
      # container networks
      host    all             all             10.244.0.0/16  password
```

    
- Reload der Config:
`su postgres -c "pg_ctl reload`