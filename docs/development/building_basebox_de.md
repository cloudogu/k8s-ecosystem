# Aufbau der EcoSystem Development Base-Boxen

Dieses Dokument enthält die notwendigen Informationen, um die Entwicklungs-Base-Boxen zu bauen, die für den Start einer
Entwicklungsinstanz des Cloudogu EcoSystems erforderlich sind. Im Allgemeinen gibt es zwei Base-Boxen. Eine für den
Hauptknoten und eine für einen Arbeitsknoten. Die Base-Boxen enthalten gemeinsame Tools und Installationen, um den
Aufwand für die Erstellung einer neuen Entwicklungsinstanz über Vagrant zu reduzieren.

## Voraussetzungen

- `git` installiert
- `packer` installiert (siehe [packer.io](https://www.packer.io/))
- VirtualBox" installiert
- Verstehen der [Struktur der Projektdateien](structure_of_the_files_de.md)

## Bauen des Hauptknotens Basebox

**1. Klonen Sie das k8s-ecosystem Repository**

```bash
git clone https://github.com/cloudogu/k8s-ecosystem.git
```

**2. Image erstellen**

```bash
cd <k8s-oekosystem-pfad>/image/
packer build k8s-dev-main.json
```

**3. Warten**

Der Image-Erstellungsprozess dauert etwa 15 Minuten, abhängig von Ihrer Hardware und Internetverbindung. Packer sollte
eine resultierende Basebox mit dem Namen `ecosystem-basebox-main.box` im `build` Ordner erstellen.

## Erstellen der Worker Node Basebox

**1. Klonen Sie das k8s-ecosystem Repository**

```bash
git clone https://github.com/cloudogu/k8s-ecosystem.git
```

**2. Image erstellen**

```bash
cd <k8s-oekosystem-pfad>/image/
packer build k8s-dev-worker.json
```

**3. Warten**

Der Image-Erstellungsprozess dauert etwa 15 Minuten, abhängig von Ihrer Hardware und Internetverbindung. Packer sollte
eine Basebox mit dem Namen `ecosystem-basebox-worker.box` im Ordner `build` erstellen.