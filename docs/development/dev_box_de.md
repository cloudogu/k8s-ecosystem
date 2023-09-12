# Dev-Box

Dieses Dokument enthält die notwendigen Informationen, um die Entwicklungs-Basebox lokal mit Vagrant zu starten.
Eine Anleitung für die Erstellung des Images für die Entwicklungs-Basebox ist [hier](./building_basebox_de.md) zu
finden.

### Konfiguration

Die Konfiguration für die Dev-Box erfolgt über eine `.vgarant.rb`-Datei. Diese wird vom `Vagrantfile` eingelesen und
kann
die Konfigurationswerte aus dem `Vagrantfile` überschreiben.
Folgende Konfigurationswerte können (unter anderem) angegeben werden:

| Wert                    | Beschreibung                                        |
|-------------------------|-----------------------------------------------------|
| dogu_registry_url       | Die URL der Dogu-Registry                           |
| dogu_registry_username  | Der Benutzername zu Login in die Dogu-Registry      |
| dogu_registry_password  | Das Passwort zu Login in die Dogu-Registry          |
| image_registry_url      | Die URL der Image-Registry                          |
| image_registry_username | Der Benutzername zu Login in die Image-Registry     |
| image_registry_password | Das Passwort zu Login in die Image-Registry         |
| image_registry_email    | Die E-Mail-Adresse des Benutzers der Image-Registry |
| helm_registry_url       | Die URL der Helm-Registry                           |
| helm_registry_username  | Der Benutzername zu Login in die Helm-Registry      |
| helm_registry_password  | Das Passwort zu Login in die Helm-Registry          |
| vm_memory               | Der Arbeitsspeicher der VMs                         |
| vm_cpus                 | Die Anzahl der CPUs der VMs                         |
| worker_count            | Die Anzahl der Worker-Nodes des Cluster             |
| main_k3s_ip_address     | Die IP-Adresse des Main-Nodes des Cluster           |

#### Verschlüsselung der Konfiguration

Da die Konfiguration sensible Daten enthält, sollte sie nicht Klartext gespeichert werden.
Daher ist es möglich die Daten mit `gpg` und dem Yubi-Key zu verschlüsseln und so zu speichern.
Wenn verschlüsselte Konfigurations-Daten vorhanden sind, werden diese vom `Vagrantfile` mit `gpg` und dem Yubi-Key entschlüsselt.

Um die Konfiguration in der `.vgarant.rb`-Datei zu verschlüsseln, muss folgender Befehl ausgeführt werden:
```shell
gpg --encrypt --armor --default-recipient-self .vagrant.rb
```
Anschließend kann die unverschlüsselte `.vgarant.rb`-Datei gelöscht werden.

Zum Entschlüssen kann folgender Befehl verwendet werden:
```shell
gpg --decrypt .vagrant.rb.asc > .vagrant.rb
```

> **Hinweis:** Bei Änderungen in der `.vgarant.rb` muss diese erneut verschlüsselt und anschließend gelöscht werden! 