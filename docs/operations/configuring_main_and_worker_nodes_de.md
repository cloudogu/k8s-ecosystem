# Konfigurieren der Haupt- und Arbeitsknoten

Die Haupt- und Arbeitsknoten müssen so konfiguriert werden, dass sie in Ihrem eigenen Cluster vollständig zugänglich
sind. Dieses Dokument beschreibt die vollständigen Konfigurationsoptionen.

## Format der Konfigurationsdatei

Die Arbeits- und Hauptknoten werden durch eine JSON-Datei konfiguriert, die auf jedem Knoten
unter `/etc/ces/nodeconfig/k3sConfig.json` gemountet wird. Die json-Datei hat das folgende Format:

**Beispiel: k3sConfig.json**

```json
{
  "ces-main": {
    "isMainNode": true,
    "node-ip": "192.168.56.2",
    "node-external-ip": "192.168.56.2",
    "flannel-iface": "enp0s8"
  },
  "ces-worker-0": {
    "node-ip": "192.168.56.3",
    "node-external-ip": "192.168.56.3",
    "flannel-iface": "enp0s8"
  }
}
```

Jeder Knoten erhält einen Eintrag in diese Datei. Der Bezeichner wird auf der Grundlage des Hostnamens des Knotens
gewählt, z.B. hat unser Hauptknoten hat den Hostnamen `ces-main` und unser Arbeitsknoten hat den
Hostnamen `ces-worker-0`. Die Knoten verwenden ihren Hostnamen, um die für sie relevante Konfiguration abzurufen.

## Konfigurationsoptionen

Dieser Abschnitt beschreibt die möglichen Konfigurationsoptionen für ein Node im Detail:

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

## Verwendung der Knotenkonfiguration im EcoSystem

Es ist besonders wichtig, die Konfigurationsdatei in alle Knoten unter dem Pfad `/etc/ces/nodeconfig/k3sConfig.json`
beim Starten einzubinden. Beim Start wird ein benutzerdefinierter Dienst ausgelöst, um den `k3s` oder `k3s-agent` Dienst
entsprechend zu konfigurieren. 