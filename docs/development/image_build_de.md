# Erstellung eines Kubernetes-CES-Images
## Anforderungen
- `git` installiert
- `packer` installiert (siehe [packer.io](https://www.packer.io/))
- `VirtualBox`, `QEMU` und/oder `VMware Workstation` installiert

## 1. Klonen des k8s-ecosystem-Repository
- `git clone https://github.com/cloudogu/k8s-ecosystem.git`

## 2. Start des Bauprozesses mit Packer
- `cd <k8s-ecosystem-pfad>/image/`
- `packer build -var "timestamp=$(date +%Y%m%d)" k8s-prod.json`
  - Um nur für einen bestimmten Hypervisor zu bauen, kann der `--only=`-Parameter genutzt werden
  - Beispiel: `packer build -var "timestamp=$(date +%Y%m%d)" --only=ecosystem-virtualbox k8s-prod.json`

## 3. Warten
- Der Image-Erstellungsprozess dauert etwa 15 Minuten, abhängig von Ihrer Hardware und Internetanbindung.

## 4. Beenden
- Das Image finden Sie in `<ecosystem-Pfad>/image/output-*` und als tar-Archiv in `<ecosystem-Pfad>/image/build`.
  - Der Standardbenutzer ist `ces-admin` mit dem Passwort `ces-admin`. Dieses sollte so bald wie möglich geändert werden!
  - Die Herstellung einer SSH-Verbindung ist im Dokument [SSH-Authentifizierung am Cloudogu EcoSystem](../operations/ssh_authentication_de.md) beschrieben.
