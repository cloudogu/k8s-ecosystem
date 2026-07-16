# Die Ecosystem-Entwicklungs-Basebox veröffentlichen

0. Ein Release von k8s-ecosystem erstellen, falls noch nicht existent
    - `git flow release start vX.Y.Z` vom develop-Branch ausführen
    - Changelog anpassen und committen
    - `git flow release finish -s vX.Y.Z` ausführen
    - Push via `git push origin main` and `git push origin develop --tags`
1. Eine Basebox wie in [Building Basebox](building_basebox_de.md) beschrieben erstellen
2. Eine Version zur Basebox hinzufügen
    - Den Basebox-Namen von `image/dev/build/ecosystem-basebox.box` zu `image/dev/build/basebox-mn-vX.Y.Z.box` ändern
3. Einen neuen Ordner `vX.Y.Z` im zugehörigen [Google Cloud Bucket](https://console.cloud.google.com/storage/browser/cloudogu-ecosystem?project=cloudogu-backend) erstellen
4. Die Basebox in den neuen Ordner hochladen
    - z.B. die Basebox `image/dev/build/basebox-mn-v1.0.0.box` in `basebox-mn/v1.0.0/` speichern
5. Die Datei-Zugriffsrechte bearbeiten
    - Einen Eintrag "Public/allUsers" hinzufügen und die "Reader"-Rechte zuweisen
6. Das Vagrantfile anpassen um die neue Basebox zu verwenden
    - basebox_version anpassen (to `vX.Y.Z`)
    - Die Basebox-Checksumme anpaasen (ermittelt über `sha256sum image/dev/build/basebox-mn-v1.0.0.box`)
    - Mit `vagrant up` testen
    - Commit und push
