# Erstellung eines Kubernetes-CES-Images

## Anforderungen

- `git` installiert
- `packer` installiert (siehe [packer.io](https://www.packer.io/))
- `VirtualBox`, `QEMU` und/oder `VMware Workstation` installiert

## 1. Klonen des k8s-ecosystem-Repository

- `git clone https://github.com/cloudogu/k8s-ecosystem.git`

## 2. Start des Bauprozesses mit Packer

- `cd <k8s-ecosystem-pfad>/image/prod/`
- `packer init .`
- `packer build -var "timestamp=$(date +%Y%m%d)" k8s-prod.pkr.hcl`
    - Um nur für einen bestimmten Hypervisor zu bauen, kann der `--only=`-Parameter genutzt werden
    - Beispiel: `packer build -var "timestamp=$(date +%Y%m%d)" --only=virtualbox-iso.ecosystem-virtualbox k8s-prod.pkr.hcl`

> Für VirtualBox-Installationen < 7 muss zusätzlich eine Variable gesetzt werden, weil bestimmte verwendete Optionen nicht für die Version verfügbar sind.
>
>`packer build -var "timestamp=$(date +%Y%m%d)" -var "virtualbox-version-lower-7=true" --only=virtualbox-iso.ecosystem-virtualbox k8s-prod.pkr.hcl`

## 3. Warten

- Der Image-Erstellungsprozess dauert etwa 15 Minuten, abhängig von Ihrer Hardware und Internetanbindung.

## 4. Beenden

- Das Image finden Sie in `<ecosystem-Pfad>/image/output-*` und als tar-Archiv in `<ecosystem-Pfad>/image/build`.
    - Der Standardbenutzer ist `ces-admin` mit dem Passwort `ces-admin`. Dieses sollte so bald wie möglich geändert
      werden!
    - Die Herstellung einer SSH-Verbindung ist im
      Dokument [SSH-Authentifizierung am Cloudogu EcoSystem](../operations/ssh_authentication_de.md) beschrieben.

## 5. Image in Vagrant testen

Das gebaute Image lässt sich nun lokal testen. Damit das Image von Vagrant verarbeitet werden kann, muss es vorher mit einem Namen (hier z. B. `testbox` importiert werden.

```bash
vagrant box import --name testbox build/ecosystem-basebox.box
```

Nun ist es nötig, das `Vagrantfile` in drei Bereichen anzupassen:

1. im Definitionsteil am Anfang
   - die URL- und Checksummenteile auskommentieren
   - vergebenen Namen (hier `testbox`) eintragen
2. im Teil für die Provisionierung der Hauptknoten
   - URL- und Checksummenteile auskommentieren
3. im Teil für die Provisionierung der Arbeiterknoten
   - URL- und Checksummenteile auskommentieren

```ruby
# ...
# basebox_checksum = "9f031617c1f21a172d01b6fc273c4ef95b539a5e35359773eaebdcabdff2d00f"
# basebox_checksum_type = "sha256"
# basebox_url = "https://storage.googleapis.com/cloudogu-ecosystem/basebox-mn/" + basebox_version + "/basebox-mn-" + basebox_version + ".box"
basebox_name = "testbox"

# ...
Vagrant.configure("2") do |config|
  config.vm.define "main", primary: true do |main|
    main.vm.box = basebox_name

    # main.vm.box_url = basebox_url
    # main.vm.box_download_checksum = basebox_checksum
    # main.vm.box_download_checksum_type = basebox_checksum_type
    # ...
  end
end
#...
(0..(worker_count - 1)).each do |i|
  config.vm.define "worker-#{i}" do |worker|
    worker.vm.hostname = "ces-worker-#{i}"

    worker.vm.box = basebox_name
    # worker.vm.box_url = basebox_url
    # worker.vm.box_download_checksum = basebox_checksum
    # worker.vm.box_download_checksum_type = basebox_checksum_type
    # ...
  end
end
#...
```

Das gebaute Image lässt sich nun wie üblich starten:

```bash
vagrant up
```
