# Installation in anderen Cloud-Providern
Die Installations-Skripte um des CES in einem bereitgestellten Kubernetes-Cluster zu installieren sind im Ordner `externalcloud` zu finden.

## Vorbereitung

### .env.sh
Die Installation benötigt Anhaben zum Kubectl-Context und der Dogu-Registry. 
Diese können als Umgebungs-Variablen über eine `.env.sh`-Datei im Installations-Ordner bereitgestellt werden.

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
Hier können u.a. Der FQDN und der Admin-User konfiguriert werden.

### Cloud-Provider
Hinweise zu einzelnen Cloud-Providern sind hier zu finden:
- [GoogleCloud](cloud-provicer_installation_google_cloud_de.md)
- [Azure AKS](cloud-provicer_installation_azure_aks_de.md)

## Installation
Die Installation wird durch Ausführung der `install.sh`-Datei gestartet:

```shell
./install.sh
```

> Longhorn: Um Longhorn zu installieren, muss `./installLonghorn.sh` in der `install.sh` einkommentiert werden.

## Nacharbeiten

### FQDN-Änderung
Wenn als FQDN eine IP-Adresse verwendet wird und diese vor der Installation nicht korrekt in der `setup.json` angegeben wurde, muss diese nachträglich geändert werden:
- Die Externe IP kann aus dem k8s-Service für den IngressController ausgelesen werden
- Im "etcd-client"-Deployment kann die Anpassung der FQDN vorgenommen werden `etcdctl set /config/_global/fqdn <IP>`
- Anschließend wird das selbst-signierte Zertifikat automatisch neu erstellt
- Zusätzlich sollten der CAS und alle anderen bereits installierten Dogus neugestartet werden 

### Postgresql

- Postgres-Container hat eine andere Routing-Tabelle. Das Dogu verarbeitet nur die genaue. 0.0.0.0 wir ignoriert.
    - Muss im Dogu behoben werden
    - `/var/lib/postgresql/pg_hba.conf` bearbeiten und die Subnetmask des Container-Netzwerks anpassen. Zum Beispiel von `24` auf `16`:
      ```
      # container networks
      host    all             all             10.244.0.0/16  password
      ```

    - Reload der Config:
        - `su - postgres`
        - `PGDATA=/var/lib/postgresql pg_ctl reload`