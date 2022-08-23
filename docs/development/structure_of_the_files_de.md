# Struktur der Projektdateien

Das Verzeichnis `image` enthält die folgenden Dateien:

```
📦image
 ┣ (📂 build)              - Enthält die resultierenden Base-Boxen nach deren Erstellung.
 ┣ 📂 http                 - Enthält Informationen für Subiquity (den Ubuntu-Installer seit 20.04) für:
 ┃ ┗ 📂 dev                   - die Basebox der Entwickler.
 ┃ ┗ 📂 prod                  - die Produktions-Images.
 ┣ 📂 scripts              - Enthält verschiedene Skripte:
 ┃ ┗ 📂 dev                   - Entwicklungsskripte, die beim Erstellen der Entwicklungs-Baseboxen und -Instanzen ausgeführt werden.
 ┃ ┗ 📂 kubernetes            - Skripte zur Einrichtung von k8s.
 ┃ ┗ 📜 *.sh                  - allgemeine Skripte, die für alle Images und Baseboxen gelten.
 ┣ 📜 k8s-dev-main.json    - Packer-Vorlage, die zur Erstellung der Entwicklungs-Basebox für den Hauptknoten verwendet wird.
 ┣ 📜 k8s-dev-worker.json  - Packer-Vorlage zum Erstellen der Entwicklungs-Basebox für die Arbeitsknoten.
 ┗ 📜 k8s-prod.json        - Packer-Vorlage für die Erstellung der Produktions-Images für verschiedene Hypervisor.
```