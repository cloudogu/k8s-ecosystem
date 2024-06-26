# Struktur der Projektdateien

Das Verzeichnis `image` enthält die folgenden Dateien:

```
📦image
 ┣ (📂 build)              - Enthält die resultierenden Baseboxen nach deren Erstellung.
 ┣ 📂 http                 - Enthält Informationen für Subiquity (den Ubuntu-Installer seit 20.04) für:
 ┃ ┗ 📂 dev                   - die Basebox der Entwickler.
 ┃ ┗ 📂 prod                  - die Produktions-Images.
 ┣ 📂 scripts              - Enthält verschiedene Skripte:
 ┃ ┗ 📂 dev                   - Entwicklungsskripte, die beim Erstellen der Entwicklungs-Baseboxen und -Instanzen ausgeführt werden.
 ┃ ┗ 📂 kubernetes            - Skripte zur Einrichtung von k8s.
 ┃ ┗ 📜 *.sh                  - allgemeine Skripte, die für alle Images und Baseboxen gelten.
 ┣ 📂 dev
 ┃ ┗ 📜 k8s-dev.pkr.hcl         - Packer-Vorlage, die zur Erstellung der Entwicklungs-Basebox verwendet wird.
 ┣ 📂 prod
   ┗ 📜 k8s-prod.pkr.hcl        - Packer-Vorlage für die Erstellung der Produktions-Images für verschiedene Hypervisor.
```