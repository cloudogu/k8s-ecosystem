# Konfigurieren der Haupt- und Arbeitsknoten

Die Haupt- und Arbeitsknoten müssen so konfiguriert werden, dass sie in Ihrem eigenen Cluster vollständig zugänglich
sind. Dieses Dokument beschreibt die vollständigen Konfigurationsoptionen.

## Format der Konfigurationsdatei

Die Arbeits- und Hauptknoten werden durch eine JSON-Datei konfiguriert, die auf jedem Knoten
unter `/etc/ces/nodeconfig/k3sConfig.json` gemountet wird. Die json-Datei hat das folgende Format:

**Beispiel: k3sConfig.json**

```json
{
  "ces-namespace": "ecosystem",
  "k3s-token": "SuPeR_secure123!TOKEN",
  "nodes": [
    {
      "name": "ces-main",
      "isMainNode": true,
      "node-ip": "192.168.56.2",
      "node-external-ip": "192.168.56.2",
      "flannel-iface": "enp0s8"
    },{
      "name": "ces-worker-0",
      "node-ip": "192.168.56.3",
      "node-external-ip": "192.168.56.3",
      "flannel-iface": "enp0s8"
    }
  ],
  "docker-registry-configuration": {
    "mirrors": {
      "docker.io": {
        "endpoint": [
          "https://192.168.179.19"
        ]
      }
    },
    "configs": {
      "192.168.179.18": {
        "auth": {
          "username": "ces-admin",
          "password": "ces-admin"
        }
      }
    }
  }
}
```

Jeder Knoten erhält einen Eintrag in dieser Datei. Um die richtige Konfiguration herauszufinden, versuchen die Knoten,
ihren Hostnamen mit dem Feld `name` jedes `nodes`-Objekts abzugleichen.

## CES-Namespace

Der Eintrag `ces-namespace` gibt an, in welchem kubernetes-Namespace das CES installiert wird.

## k3s Token

Mit dem Eintrag `k3s-token` können Sie den Token angeben, den die Knoten zur Authentifizierung innerhalb des Clusters verwenden werden.
Dieser Token kann nicht mehr geändert werden, sobald der Cluster installiert ist.

## docker-registry-configuration

Mit dem Eintrag `docker-registry-configuration` können Sie private Docker-Registries für k3s konfigurieren.
Dabei können Mirrors für bestimmte Registries angegeben werden. Jeder Mirror kann über das `configs`-Objekt
konfiguriert werden. Die `docker-registry-configuration` wird auf dem Node (Main und Worker) unter `/etc/rancher/k3s/`
abgelegt.

## Konfigurationsoptionen

Dieser Abschnitt beschreibt die möglichen Konfigurationsoptionen für ein Node im Detail:

**Name**

```
Option: name
Erforderlich: ja
Beschreibung:       Diese Option enthält den Namen des Knotens (Host).
Akzeptierte Werte:   Jeder gültige Hostname
```

**isMainNode**

```
Option: isMainNode
Erforderlich: Nein
Beschreibung:       Dieses Flag legt fest, ob ein Knoten der Hauptknoten ist.
Akzeptierte Werte: true|false
Standardwert: false
```

**flannel-iface**

```
Option: flannel-iface
Erforderlich: ja
Beschreibung:       Diese Option enthält den für k3s verwendeten Schnittstellenbezeichner.
Akzeptierte Werte: jeder gültige Schnittstellenname (ip a | grep ": ")
```

**node-ip**

```
Option: node-ip
Erforderlich: ja
Beschreibung:       Die IP des Knotens, der über die angegebene Flannel-iface erreichbar ist.
Akzeptierte Werte:   Gültige IPv4-Adresse (xxx.xxx.xxx.xxx)
```

**node-external-ip**

```
Option: node-external-ip
Erforderlich: ja
Beschreibung:       Die externe IP des Knotens. Kann dieselbe sein wie die node-ip.
Akzeptierte Werte:   Gültige IPv4-Adresse (xxx.xxx.xxx.xxx)
```

Dieser Abschnitt beschreibt die möglichen Konfigurationsoptionen für die `docker-registry-configuration` im Detail:

Die Konfigurationsoptionen bilden die Optionen für die `registries.yaml` für k3s von Rancher ab.
Diese sind [hier](https://docs.k3s.io/installation/private-registry) zu finden.

Eine vollstände Konfiguration könnte wie folgend aussehen:

```json
{
  "docker-registry-configuration": {
    "mirrors": {
      "docker.io": {
        "endpoint": [
          "https://192.168.179.19",
          "https://192.168.179.20"
        ]
      },
      "registry.cloudogu.com": {
        "endpoint": [
          "https://192.168.179.19"
        ]
      }
    },
    "configs": {
      "192.168.179.19": {
        "auth": {
          "username": "ces-admin",
          "password": "ces-admin"
        },
        "tls": {
          "cert_file": "path to the cert file used in the registry",
          "key_file":  "path to the key file used in the registry",
          "ca_file": "path to the ca file used in the registry",
          "insecure_skip_verify": false
        }
      },
      "192.168.179.20": {
        "auth": {
          "token": "token"
        }
      }
    }
  }
}
```

## Verwendung der Knotenkonfiguration im EcoSystem

Es ist besonders wichtig, die Konfigurationsdatei in alle Knoten unter dem Pfad `/etc/ces/nodeconfig/k3sConfig.json`
beim Starten einzubinden. Beim Start wird ein benutzerdefinierter Dienst ausgelöst, um den `k3s` oder `k3s-agent` Dienst
entsprechend zu konfigurieren.

## Troubleshooting

### Gleicher Hostname von Worker und Main bei Worker-Initialisierung

Durch Verwendung eines gleichen Hostnames bei der Initialisierung eines Workers kann es zu einer fehlerhaften
Konfiguration kommen.

Beim Start des k3s-agent's erscheint folgende Meldung:

`Failed to retrieve agent config: Node password rejected, duplicate hostname or contents of '/etc/rancher/node/password'
may not match server node-passwd entry, try enabling a unique node name with the --with-node-id flag`

#### Lösung:

`/usr/local/bin/k3s-uninstall.sh` auf Worker ausführen.

Prüfen, ob alte Credentials vom Worker-Node existieren: `kubectl get secrets --namespace=kube-system`

Falls ja: `kubectl delete secret <worker>.node-password.k3s --namespace=kube-system`

Prüfen, ob Worker noch als Node gelistet ist: `kubectl get nodes`

Falls ja: `kubectl delete node <worker>`




