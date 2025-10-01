# Dev-Box

Dieses Dokument enthält die notwendigen Informationen, um die Entwicklungs-Basebox lokal mit Vagrant zu starten.
Eine Anleitung für die Erstellung des Images für die Entwicklungs-Basebox ist [hier](./building_basebox_de.md) zu
finden.

### Vorbedingungen

#### Applikationen

Folgende Applikationen müssen installiert sein:

- [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - Kommandozeilen-Tool zur Verwaltung des
  Kubernetes-Clusters
- [Helm](https://helm.sh/docs/intro/quickstart/) - Paketmanager für Kubernetes

Folgende Applikationen werden zur leichteren Handhabung empfohlen:

- [kubectx + kubens](https://github.com/ahmetb/kubectx) - Einfacheres Wechseln zwischen Kubernetes-Kontexten und
  -Namespaces
- [k9s](https://k9scli.io/topics/install/) - UI (im Terminal) zur einfacheren Verwaltung des Clusters

#### Dateisystem

- Gegebenenfalls muss der Ordner `~/.kube` angelegt werden
- in `/etc/hosts` folgenden Eintrag ergänzen: `192.168.56.2     k3ces.local`
- Umgebungsvariable setzen: `export KUBECONFIG=~/.kube/config:~/.kube/k3ces.local`
- in `/etc/docker/daemon.json` folgenden Eintrag ergänzen: `{ "insecure-registries": ["k3ces.local:30099"] }`
  (wird benötigt, um beim Entwickeln eigene Images in die Helm-Registry zu pushen)

### Konfiguration

Die Konfiguration für die Dev-Box erfolgt über eine `.vagrant.rb`-Datei. Es existiert eine Template-Datei
`.vagrant.rb.template`,
die als guter Startpunkt dienen kann. Die `.vagrant.rb`-Datei wird vom `Vagrantfile` eingelesen und
kann die Konfigurationswerte aus dem `Vagrantfile` überschreiben.

**Um sicherzustellen, dass Sonderzeichen von der Vagrantdatei oder nachfolgenden Shell-Skripten wörtlich behandelt
werden,
geben Sie bitte Ihre Passwörter in der Base64-Kodierung an. Bitte nutzen Sie dafür folgenden Befehl:
`printf '%s' 'password' | base64 -w0`**

Folgende Konfigurationswerte können (unter anderem) angegeben werden:

| Wert                     | Beschreibung                                                                                                                                                                                          |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| dogu_registry_url        | Die URL der Dogu-Registry                                                                                                                                                                             |
| dogu_registry_username   | Der Benutzername zum Login in die Dogu-Registry                                                                                                                                                       |
| dogu_registry_password   | Das Passwort zum Login in die Dogu-Registry                                                                                                                                                           |
| image_registry_url       | Die URL der Image-Registry                                                                                                                                                                            |
| image_registry_username  | Der Benutzername zum Login in die Image-Registry                                                                                                                                                      |
| image_registry_password  | Das Passwort zum Login in die Image-Registry                                                                                                                                                          |
| image_registry_email     | Die E-Mail-Adresse des Benutzers der Image-Registry                                                                                                                                                   |
| helm_registry_host       | Der Host der Helm-Registry                                                                                                                                                                            |
| helm_registry_schema     | Das Schema der Helm-Registry                                                                                                                                                                          |
| helm_registry_plain_http | Wird die Helm-Registry über HTTP oder HTTPS erreicht?                                                                                                                                                 |
| helm_registry_username   | Der Benutzername zum Login in die Helm-Registry                                                                                                                                                       |
| helm_registry_password   | Das Passwort zum Login in die Helm-Registry                                                                                                                                                           |
| vm_memory                | Der Arbeitsspeicher der VMs                                                                                                                                                                           |
| vm_cpus                  | Die Anzahl der CPUs der VMs                                                                                                                                                                           |
| worker_count             | Die Anzahl der Worker-Nodes des Cluster                                                                                                                                                               |
| main_k3s_ip_address      | Die IP-Adresse des Main-Nodes des Cluster                                                                                                                                                             |
| certificate_type         | `selfsigned` oder `mkcert`; siehe [Zertifikate](#zertifikate)                                                                                                                                         |
| forceUpgradeEcosystem    | default: `false`; wenn `true` wird bei jedem `vagrant up` das ecosystem-core Helm-release und das Blueprint aktualisiert ; siehe [Blueprint & Update des Ecosystem](#blueprint--update-des-ecosystem) |

#### Verschlüsselung der Konfiguration

Da die Konfiguration sensible Daten enthält, sollte sie nicht Klartext gespeichert werden.
Daher ist es möglich die Daten mit `gpg` und dem Yubi-Key zu verschlüsseln und so zu speichern.
Wenn verschlüsselte Konfigurations-Daten vorhanden sind, werden diese vom `Vagrantfile` mit `gpg` und dem Yubi-Key
entschlüsselt.

Um die Konfiguration in der `.vagrant.rb`-Datei zu verschlüsseln, muss folgender Befehl ausgeführt werden:

```shell
gpg --encrypt --armor --default-recipient-self .vagrant.rb
```
Di verschlüsselte Datei hat den Namen `.vagrant.rb.asc`.

Anschließend kann die unverschlüsselte `.vagrant.rb`-Datei gelöscht werden.

Zum Entschlüssen kann folgender Befehl verwendet werden:

```shell
gpg --decrypt .vagrant.rb.asc > .vagrant.rb
```

> **Hinweis:** Bei Änderungen in der `.vagrant.rb` muss diese erneut verschlüsselt und anschließend gelöscht werden!

### Zertifikate
In der DEV-Box erstellt das Setup des CES standardmäßig ein selbstsigniertes SSL-Zertifikat für die Absicherung der HTTPS-Verbindungen.
Das hat den Nachteil, dass Browser diesem Zertifikat nicht vertrauen und dafür Ausnahmen im Browser eingerichtet werden müssen.
Um das zu vermeiden, kann für die Entwicklung beim Erstellen der Dev-Box ein Zertifikat verwendet werden, das mit dem Tool [mkcert](https://github.com/FiloSottile/mkcert) erstellt wird. 
Diesem Zertifikat wird lokal auf dem Entwicklungs-Rechner vertraut.

Nachdem `mkcert`[installiert](https://github.com/FiloSottile/mkcert#installation) wurde, muss es einmalig mit folgendem Befehl initialisiert werden:
```shell
mkcert -install
```

Anschließend kann in der [Konfiguration](#konfiguration) der Wert für `certificate_type` auf `mkcert` gesetzt werden.
Wenn noch kein Zertifikat existiert, erstellt das `Vagrantfile` dann mit `mkcert` ein neues Zertifikat, das im CES verwendet wird.

### Blueprint & Update des Ecosystem

Beim initialen Starten der DEV-Box mit `vagrant up` wird das "ecosystem-core" Helm-Chart und ein Blueprint mit folgenden Dogus installiert:
* ldap
* postfix
* cas
* usermgt

Die Dogus werden mit ihrer jeweils aktuellsten Version im Blueprint eingetragen.

Wenn das Blueprint erfolgreich angewendet wurde (Condition `Completed: True`), wird es auf `stopped: true` gesetzt.
Das hat zur Folge, dass das Blueprint nicht mehr automatisch angewendet wird und somit auch weitere Dogus manuell installiert werden können, ohne dass der Blueprint-Operator diese löscht oder verändert.

#### Update erzwingen
Nach dem initialen Starten der DEV-Box wird bei folgenden Starts mit `vagrant up` überprüft ob das Helm-Release `ecosystem-core` bereits installiert ist. 
Wenn das der Fall ist, werden keine weiteren Schritte ausgeführt.
Über die Konfiguration `forceUpgradeEcosystem` in der `.vagrant.rb`-Datei, kann dieses Verhalten deaktiviert werden.
Dann wird das Helm-Release `ecosystem-core` und das Blueprint bei jedem `vagrant up` aktualisiert.

#### Blueprint-Override

Um zusätzliche Dogus mitzuinstallieren oder Versionen zu überschreiben, kann eine Datei `.blueprint-override.yaml` im Root-Verzeichnis abgelegt werden. 
Diese Datei wird beim Erstellen des Blueprints mit der generierten Blueprint-Datei zusammengeführt.

Vorgehen:
1. Template kopieren:
   `cp .blueprint-override.yaml.template .blueprint-override.yaml`
2. Inhalte anpassen (z. B. zusätzliche Dogus oder spezifische Versionen definieren).
3. `vagrant up` ausführen. Die Datei wird automatisch in den Blueprint gemergt und angewendet.

Hinweise:
- Die Datei muss exakt `.blueprint-override.yaml` heißen und im Root-Verzeichnis liegen.
- Werte aus der Override-Datei überschreiben gleichnamige Einträge der generierten Blueprint-Datei.
- Syntax und Struktur müssen dem Blueprint-Schema entsprechen.
