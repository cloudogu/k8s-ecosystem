# Dev-Box mit k3d

Dieses Dokument beschreibt eine leichtgewichtige Alternative zur Vagrant-basierten Dev-Box. Statt eine VM zu starten, läuft der Kubernetes-Cluster direkt in Docker über `k3d`.

## Aktueller Umfang

Der `k3d`-Pfad ist dafür gedacht, mehrere lokale CES-Instanzen über einen kleinen Manager zu verwalten. Für den Bootstrap wird das bestehende [`installEcosystem.sh`](../../image/scripts/dev/installEcosystem.sh) direkt gegen die jeweilige `kubeconfig` verwendet.

Im Unterschied zum Vagrant-Setup bildet dieser Pfad aktuell nicht nach:

- das Basebox-Image
- die Node-Konfiguration aus `nodeconfig/k3sConfig.json`

Der bisherige Proxy-Registry-Ansatz wird hier nicht mehr im Cluster selbst betrieben, sondern als lokaler Docker-basierter Registry-Stack außerhalb der Cluster.

## Voraussetzungen

- `docker`
- `k3d`
- `kubectl`
- `helm`
- `curl`
- `jq`
- `yq`

## Einmalige Konfiguration

Aus dem Root-Verzeichnis des Repos:

```shell
cp k3d/config.env.template k3d/config.env
```

Danach die Zugangsdaten in `k3d/config.env` eintragen.

Wichtige Punkte:

- Die Datei enthält gemeinsame Defaults für alle lokalen `k3d`-Ecosystems.
- Longhorn ist für `k3d` standardmäßig deaktiviert, weil `k3d` bereits die StorageClass `local-path` mitbringt.
- Für `k3d` wird ein interner CoreDNS-Eintrag gesetzt, damit Pods den jeweiligen CES-FQDN auf den Service `ces-loadbalancer` auflösen können.
- Standardmäßig wird ein lokaler Registry-Stack mit zwei Endpunkten verwendet:
  - eine schreibbare Dev-Registry für `docker push` und `helm push`
  - eine Proxy-Registry als Pull-Through-Cache für `registry.cloudogu.com`
  - beide teilen sich dasselbe Storage-Verzeichnis
- Das bestehende `.blueprint-override.yaml`-Verhalten funktioniert weiter, weil derselbe Blueprint-Mechanismus verwendet wird.
- Wenn das CES bei einem erneuten Bootstrap aktualisiert werden soll, kann in `k3d/config.env` `FORCE_UPGRADE_ECOSYSTEM="true"` gesetzt werden.

Der Registry-Stack lässt sich auch separat verwalten:

```shell
k3d/registry.sh start
k3d/registry.sh status
```

## Neues Ecosystem erzeugen

Der Manager erstellt den `k3d`-Cluster, legt eine dedizierte `kubeconfig` an und installiert anschließend das CES:

```shell
k3d/ecosystem.sh create mein-ces
```

Dabei werden automatisch vergeben:

- FQDN: `mein-ces.k3ces.localdomain`
- Kubeconfig: `~/.kube/mein-ces.k3ces.localdomain`
- Host-IP: nächste freie Loopback-IP aus `127.0.0.0/24`
- Kubernetes-API-Port: nächster freier Port ab `6550`
- Merge in die Standard-Kubeconfig: `~/.kube/config` ohne automatischen Context-Wechsel
- Default-Namespace im Context: `ecosystem`
- `/etc/hosts`-Eintrag per `sudo`, sofern `MANAGE_HOSTS_FILE="true"` gesetzt ist
- lokaler Registry-Stack vor dem Cluster-Create gestartet, sofern `LOCAL_REGISTRY_ENABLED="true"` gesetzt ist

Welche IP für ein Ecosystem verwendet wird, zeigt:

```shell
k3d/ecosystem.sh list
```

## Ecosystems verwalten

```shell
k3d/ecosystem.sh list
k3d/ecosystem.sh open mein-ces
k3d/ecosystem.sh stop mein-ces
k3d/ecosystem.sh start mein-ces
k3d/ecosystem.sh delete mein-ces
```

`start` und `stop` verwenden direkt die entsprechenden `k3d`-Kommandos. `delete` entfernt zusätzlich die verwaltete `kubeconfig` und die generierte Instanz-Konfiguration unter `k3d/environments/`.

`open` öffnet `https://<fqdn>` im Standard-Browser des Hosts.

Standardmäßig werden dabei außerdem:

- der Context in `~/.kube/config` eingetragen
- der zugehörige `/etc/hosts`-Eintrag aktualisiert oder entfernt
- die lokale Proxy-Registry bei `create` und `start` automatisch gestartet

Dieses Verhalten kann über `k3d/config.env` gesteuert werden:

- `MERGE_DEFAULT_KUBECONFIG`
- `SWITCH_DEFAULT_KUBECONFIG_CONTEXT`
- `DEFAULT_KUBECONFIG_PATH`
- `MANAGE_HOSTS_FILE`
- `LOCAL_REGISTRY_ENABLED`
- `LOCAL_REGISTRY_STORAGE_PATH`
- `LOCAL_REGISTRY_DEV_PORT`
- `LOCAL_REGISTRY_PROXY_PORT`
- `LOCAL_REGISTRY_CLUSTER_PORT`

## Registry-Workflow für lokale Entwicklung

Der Registry-Stack liefert zwei verschiedene Endpunkte:

- Push vom Host: `localhost:<LOCAL_REGISTRY_DEV_PORT>`
- Konsum im Cluster: `k3d-<LOCAL_REGISTRY_PROXY_NAME>:<LOCAL_REGISTRY_CLUSTER_PORT>`

Das ist bewusst getrennt:

- lokale Images und OCI-Charts werden in die Dev-Registry gepusht
- CES-Komponenten und lokale Dogu-/Chart-Tests sollen die Proxy-Registry verwenden
- wenn ein Artefakt dort nicht lokal vorhanden ist, zieht die Proxy-Registry es von `registry.cloudogu.com`

Damit lokale Artefakte Vorrang vor dem Upstream haben, sollten sie unter derselben Repository-Struktur, aber mit eigenen Dev-Tags/-Versionen in die Dev-Registry gepusht werden.

## Manuelle Low-Level-Skripte

Die Manager-Skripte verwenden intern diese beiden Hilfsskripte:

- `k3d/cluster.sh` für Cluster-Erzeugung und `kubeconfig`
- `k3d/install.sh` für den CES-Bootstrap auf einem bestehenden Cluster
- `k3d/registry.sh` für die lokale Dev-/Proxy-Registry

Falls ein Bootstrap erneut für ein bestehendes Ecosystem ausgeführt werden soll, geht das direkt über:

```shell
k3d/install.sh k3d/environments/mein-ces.env
```
