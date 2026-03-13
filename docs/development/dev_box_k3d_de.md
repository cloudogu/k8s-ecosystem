# Dev-Box mit k3d

Dieses Dokument beschreibt eine leichtgewichtige Alternative zur Vagrant-basierten Dev-Box. Statt eine VM zu starten, läuft der Kubernetes-Cluster direkt in Docker über `k3d`.

## Aktueller Umfang

Der `k3d`-Pfad ist dafür gedacht, mehrere lokale CES-Instanzen über einen kleinen Manager zu verwalten. Für den Bootstrap wird das bestehende [`installEcosystem.sh`](../../image/scripts/dev/installEcosystem.sh) direkt gegen die jeweilige `kubeconfig` verwendet.

Im Unterschied zum Vagrant-Setup bildet dieser Pfad aktuell nicht nach:

- das Basebox-Image
- die Node-Konfiguration aus `nodeconfig/k3sConfig.json`
- den In-Cluster-Proxy-Registry-Workflow für Komponenten- und Chart-Entwicklung

Wenn der bestehende Proxy-Registry-Workflow auf den Ports `30098` und `30099` benötigt wird, bleibt die Vagrant-Variante derzeit der vollständigere Weg.

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
- Das bestehende `.blueprint-override.yaml`-Verhalten funktioniert weiter, weil derselbe Blueprint-Mechanismus verwendet wird.
- Wenn das CES bei einem erneuten Bootstrap aktualisiert werden soll, kann in `k3d/config.env` `FORCE_UPGRADE_ECOSYSTEM="true"` gesetzt werden.

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

Dieses Verhalten kann über `k3d/config.env` gesteuert werden:

- `MERGE_DEFAULT_KUBECONFIG`
- `SWITCH_DEFAULT_KUBECONFIG_CONTEXT`
- `DEFAULT_KUBECONFIG_PATH`
- `MANAGE_HOSTS_FILE`

## Manuelle Low-Level-Skripte

Die Manager-Skripte verwenden intern diese beiden Hilfsskripte:

- `k3d/cluster.sh` für Cluster-Erzeugung und `kubeconfig`
- `k3d/install.sh` für den CES-Bootstrap auf einem bestehenden Cluster

Falls ein Bootstrap erneut für ein bestehendes Ecosystem ausgeführt werden soll, geht das direkt über:

```shell
k3d/install.sh k3d/environments/mein-ces.env
```
