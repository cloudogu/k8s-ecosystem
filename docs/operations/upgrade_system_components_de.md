# Aktualisierung von Systemkomponenten

## k3s

### Manuelles Upgrade

> Info: Die Main-Nodes müssen immer zuerst aktualisiert werden.

#### Installationsskript

Ein Upgrade kann durch ein erneutes Ausführen des Installationsskript ausgeführt werden:

`INSTALL_K3S_VERSION=vX.Y.Z-rc1 /home/<user>/install.sh <EXISTING_K3S_ARGS>`

Für aktuelle argument siehe: [setupMainNode.sh](../../resources/usr/sbin/setupMainNode.sh)

Für weitere Informationen siehe: [Rancher-Dokumentation](https://docs.k3s.io/upgrades/manual#upgrade-k3s-using-the-installation-script)

#### Binary

Es ist ebenfalls möglich k3s durch den Tausch des Binarys zu aktualisieren:

Siehe: [Rancher-Dokumentation](https://docs.k3s.io/upgrades/manual#manually-upgrade-k3s-using-the-binary)

### Automatisiertes Upgrade

Für automatisierte Upgrades könnte der [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) von Rancher verwendet werden.
Dieser Controller ist hoch priviligiert und bietet mit seiner `Plan` Custom-Resource an, System-Komponenten zu aktualisieren (ebenfalls z.B. APT-Pakete).

Das Cloudogu EcoSystem bietet aktuell keine Komponente für diese Methode an.

## Info

### Neustart von k3s Main-Nodes

`sudo systemctl restart k3s`

### Neustart von k3s Agent-Nodes

`sudo systemctl restart k3s-agent`