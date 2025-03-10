# Aufbau der EcoSystem Development Baseboxe

Dieses Dokument enthält die notwendigen Informationen, um die Entwicklungs-Basebox zu bauen, die für den Start einer
Entwicklungsinstanz des Cloudogu EcoSystems erforderlich sind. Die Basebox enthält Tools und Installationen, um den
Aufwand für die Erstellung einer neuen Entwicklungsinstanz über Vagrant zu reduzieren.

## Voraussetzungen

- `git` installiert
- `packer` installiert (siehe [packer.io](https://www.packer.io/))
- packer-virtualbox-plugin via `packer plugins install github.com/hashicorp/virtualbox`
- packer-vagrant-plugin via `packer plugins install github.com/hashicorp/vagrant`
- VirtualBox installiert
- Verstehen der [Struktur der Projektdateien](structure_of_the_files_de.md)

## Bauen der Basebox

**1. Klonen Sie das k8s-ecosystem Repository**

```bash
git clone https://github.com/cloudogu/k8s-ecosystem.git
```

**2. Image erstellen**

```bash
cd <k8s-ecosystem-pfad>/image/dev/
packer init .
packer build k8s-dev.pkr.hcl
```

> Für VirtualBox-Installationen < 7 muss zusätzlich eine Variable gesetzt werden, weil bestimmte verwendete Optionen nicht für die Version verfügbar sind.
>
>`packer build -var "virtualbox-version-lower-7=true" k8s-dev.pkr.hcl`


**3. Warten**

Der Image-Erstellungsprozess dauert etwa 15 Minuten, abhängig von Ihrer Hardware und Internetverbindung. Packer sollte
eine resultierende Basebox mit dem Namen `ecosystem-basebox.box` im `image/build` Ordner erstellen.
