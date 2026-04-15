# Dev-Box mit k3d

Dieses Dokument beschreibt eine leichtgewichtige Alternative zur Vagrant-basierten Dev-Box. 
Statt eine VM zu starten, läuft der Kubernetes-Cluster direkt in Docker über `k3d`.

Wichtig:
Der `k3d`-Workflow ist für schnelle lokale Entwicklung und iterative Tests gedacht. 
Er kann nicht alle Szenarien abdecken, die mit der Vagrant-basierten `k3s`-Dev-Box getestet werden können.

Aktuelle Einschränkungen gegenüber dem Vagrant-`k3s`-Cluster:

- es wird nur ein einzelner Node verwendet
- Storage basiert auf der lokalen Default-StorageClass von `k3s`
  - PVC-Vergrößerungen werden in diesem Setup nicht unterstützt
  - Backups mit Velero werden in diesem Setup nicht unterstützt

## Aktueller Umfang

Der `k3d`-Workflow ist bewusst klein gehalten. Mehrere lokale CES-Instanzen werden über genau eine CLI verwaltet:

- `create`
- `start`
- `stop`
- `list`
- `delete`

Die CLI erstellt den lokalen `k3d`-Cluster, schreibt eine dedizierte Kubeconfig und bootstrapt anschließend das CES, indem sie das bestehende [`image/scripts/dev/installEcosystem.sh`](../../image/scripts/dev/installEcosystem.sh) aufruft.
Die Hilfsskripte unter `image/scripts/dev/` bleiben damit die gemeinsame Installationsimplementierung und werden weiterhin auch von Vagrant verwendet.


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
- `k3d` verwendet standardmäßig einen Single-Node-Cluster.
- Als Storage wird die in `k3s` enthaltene Default-StorageClass `local-path` verwendet.
- Jede Instanz bekommt:
  - eine eigene Loopback-IP aus `127.0.0.0/24`
  - einen eigenen Kubernetes-API-Port ab `6550`
  - eine eigene Kubeconfig in `~/.kube/<fqdn>`
- Die cluster-interne CES-FQDN wird über ein gemountetes CoreDNS-Manifest auf `ces-loadbalancer.ecosystem.svc.cluster.local` umgeschrieben.
- Standardmäßig wird ein lokaler Registry-Stack mit zwei Endpunkten verwendet:
  - eine schreibbare Dev-Registry für `docker push` und `helm push`
  - eine Proxy-Registry als Pull-Through-Cache für `registry.cloudogu.com`
  - beide teilen sich dasselbe Storage-Verzeichnis
- `.blueprint-override.yaml` funktioniert weiter, weil derselbe Blueprint-Mechanismus verwendet wird.
- Wenn das CES bei erneutem Bootstrap aktualisiert werden soll, kann in `k3d/config.env` `FORCE_UPGRADE_ECOSYSTEM="true"` gesetzt werden.

## Kommandos

In das `k3d`-Verzeichnis wechseln:

```shell
cd k3d
```

Verfügbare Kommandos anzeigen:

```shell
./ces-k3d --help
```

Der öffentliche Workflow besteht aus:

```shell
./ces-k3d create mein-ces
./ces-k3d list
./ces-k3d start mein-ces
./ces-k3d stop mein-ces
./ces-k3d delete mein-ces
```

## Neues Ecosystem erzeugen

Eine neue lokale CES-Instanz wird so erstellt:

```shell
./ces-k3d create mein-ces
```

Dabei vergibt die CLI automatisch:

- FQDN: `mein-ces.k3ces.localdomain`
- Kubeconfig: `~/.kube/mein-ces.k3ces.localdomain`
- Host-IP: nächste freie Loopback-IP aus `127.0.0.0/24`
- Kubernetes-API-Port: nächster freier Port ab `6550`
- Default-Namespace im Kubeconfig-Context: `ecosystem`

Nach erfolgreichem `create` gibt die CLI die wichtigsten Folgekommandos direkt mit aus, unter anderem:

- die URL
- `export KUBECONFIG=...`
- `kubectl cluster-info`
- das `/etc/hosts`-Kommando für die CES-FQDN
- die lokalen Registry-Endpunkte

Beispiel:

```text
Ecosystem 'dev2' is ready.

URL:
  https://dev2.k3ces.localdomain

Dedicated kubeconfig:
  /home/user/.kube/dev2.k3ces.localdomain

Apply kubeconfig:
  export KUBECONFIG=/home/user/.kube/dev2.k3ces.localdomain
  kubectl cluster-info

Add to /etc/hosts if needed:
  sudo sh -c 'echo "127.0.0.3 dev2.k3ces.localdomain" >> /etc/hosts'

Registry stack:
  push:    localhost:5001
  consume: k3d-registry-proxy.localhost:5000
```

## Ecosystems verwalten

Alle verwalteten Instanzen auflisten:

```shell
./ces-k3d list
```

Die Status-Spalte zeigt den tatsächlichen Clusterzustand:

- `running`
- `stopped`
- `missing`
- `unknown`

`start` und `stop` verwenden die passenden `k3d`-Clusterkommandos. Bei `start` wird zusätzlich die dedizierte Kubeconfig aktualisiert:

```shell
./ces-k3d stop mein-ces
./ces-k3d start mein-ces
```

`delete` entfernt:

- den `k3d`-Cluster
- die dedizierte Kubeconfig
- die generierten Instanzdateien unter `k3d/environments/`

```shell
./ces-k3d delete mein-ces
```

## Registry-Workflow für lokale Entwicklung

Der Registry-Stack liefert bewusst zwei verschiedene Endpunkte:

- Push vom Host: `localhost:<LOCAL_REGISTRY_DEV_PORT>`
- Konsum im Cluster: `k3d-<LOCAL_REGISTRY_PROXY_NAME>:<LOCAL_REGISTRY_CLUSTER_PORT>`

Das ist absichtlich getrennt:

- lokale Images und OCI-Charts werden in die Dev-Registry gepusht
- CES-Komponenten und lokale Dogu-/Chart-Tests konsumieren über die Proxy-Registry
- wenn ein Artefakt dort nicht lokal vorhanden ist, zieht die Proxy-Registry es von `registry.cloudogu.com`

Für den normalen Workflow sind keine `/etc/hosts`-Einträge für die Registries nötig:

- auf dem Host wird über `localhost` zugegriffen
- im Cluster über den `k3d-...`-Containernamen

## Zertifikate

Der `k3d`-Workflow installiert keine Vagrant-Zertifikate aus `.vagrant/certs/`.

Das ist beabsichtigt:

- das Vagrant-Zertifikat ist für `k3ces.localdomain` ausgestellt
- lokale `k3d`-Instanzen verwenden instanzspezifische FQDNs wie `dev2.k3ces.localdomain`
- eine Wiederverwendung des Vagrant-Zertifikats würde daher zu SAN-Mismatches führen

Für `k3d` wird der gemeinsame Installer deshalb so ausgeführt, dass das Vagrant-Zertifikat nicht injiziert wird. 
Dadurch kann der zum Instanz-FQDN passende self-signed Zertifikatsfluss verwendet werden.

## Interne Hinweise zur Implementierung

Das Wrapper-Script ist:

- `k3d/ces-k3d`

Er baut das Go-Binary automatisch neu, sobald sich Go-Quellen unter `k3d/cmd` oder `k3d/internal` geändert haben.
