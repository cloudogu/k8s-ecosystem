# Automatische Sicherheitsupdates im CES

Es gibt [mehrere Möglichkeiten](https://help.ubuntu.com/community/AutomaticSecurityUpdates), automatische Sicherheitsupdates in Ubuntu zu aktivieren. Die häufigste ist die Verwendung des Pakets "unattended-upgrades". Dieses Paket installiert automatisch apt-Paketaktualisierungen, sobald sie verfügbar sind.
Das Paket "unattended-upgrades" ist im CES standardmäßig aktiv.

Um zu überprüfen, ob automatische Updates aktiviert sind, führen Sie den Befehl `apt-config dump APT::Periodic::Unattended-Upgrade` aus.
Die Ausgabe sollte lauten: `APT::Periodic::Unattended-Upgrade "1";`

Um unattended-upgrades zu deaktivieren, kann das Paket via `sudo apt remove unattended-upgrades` entfernt werden.