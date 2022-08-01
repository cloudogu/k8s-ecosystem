# SSH-Authentifizierung am Cloudogu EcoSystem

## Einführung

Das Cloudogu EcoSystem (CES) basiert auf Ubuntu 20.04 und hat einen aktiven SSH-Server installiert.
Die Verbindung zu diesem Server ist ausschließlich über das Public-Key-Verfahren möglich; die
Authentifizierung über Username/Passwort wurde aus Sicherheitsgründen deaktiviert. Um den/die
nötigen Public Key(s) in der Maschine abzulegen, ist es nötig, ihn/sie in einer `authorized_keys`-Datei
zu speichern und im EcoSystem unter `/etc/ces/authorized_keys` einzubinden. Diese Datei wird dann
bei einem Neustart des Systems oder des SSH-Daemons angezogen.

## Erstellen eines SSH-Public/Private-Key-Paares

Zur Erstellung eines Public/Private-Key-Paares gibt es hier eine Anleitung:
https://www.heise.de/tipps-tricks/SSH-Key-erstellen-so-geht-s-4400280.html

## Struktur der authorized_keys-Datei

Die `authorized_keys`-Datei ist so strukturiert, dass sie einen Public Key (bspw. aus
der `id_rsa.pub`-Datei aus dem vorigen Schritt) enthält. Sollen mehrere Keys enthalten
sein, können diese einfach untereinander in die Datei geschrieben werden. Jede Zeile kann am
Ende einen Kommentar enthalten, der vom Key durch ein Leerzeichen getrennt ist.
Die `authorized_keys`-Datei sieht dann beispielsweise so aus:

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDY0nVMmCeczF8jLAwnw3PNGMMAlqskpw8lfJuZeTIrAklIIeVqXmaHaCDbC+Z+/WYtp/5A9H8V6MDz7pMyrTCnm8g6nKZ0J/kH+kP8iT9f1d2V78AG1P3v6R19UeT8h3926bB/IJGmnzo53gnfdV+YhSEwsIGFI3ikzjc0GOZBAvhCLPo6WXAbcvM5+qVTFUjkQwi6lQBjtS/cIZJrcB9J9bLNJbait5itaXLyLy52Igt8dQbzB5hnvlBwUuFHnt0agXF0yxb+VVRzF0BVZ0rE0MKwCiG/mwbspIDOhuMj5DwtRiSC0LtNCn9V46cuDy1lrsUvO2g1mo3ptbhEAxv+UAStbDKkgSvKDfK3Q0AdLE6+AgZ/EehcRQvo10W5lY6JOm5PcHstFQLy4g660IiOrxrSN5HCZmRzeU49vT4o3tYxXsxSebxvumOmmnHlZUczZbRbEiSJ5L7RLRhQpJ4adkGuPWEyXXYsQtlgOlmBUZnEm9N8oaNIlknW5lUV4ZyRMAL7VdMgvwZDaqWgl1JZpp9Np3WKWizzuOOZm6jlZW3Sbsyr8Lw3SZXYSCU03gx+YZFGk+1zmwvtCp86i7gzH6lpami8mAHfEWVqaZoHWBlCU35gqaUscvWEJ7KMtQNCdHV8tMEE5IFSfigXgQjfsiqj6v+detsN+uN31PepxQ== SSHuser123
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCJi7dJnW9zB3m5iakfUwmntYLahA82WqYKM3f9VQhbpwI93zBD2SPrvH02TtEVgGvyW3oR7RMVbAOf0YEe5F6GM3qxL8r1uhitrOqblDCAz8xyVz1GfWy3v+5hMXyN3/yFpTmm8QK1V9xdIKdMcxGn5CdEpMHSODs1X7CIxs2fZ2Kw4kzCOY064+wfwGpnaJhbABpNnEudLAHkphZWSB0wF0kVrcU4GJaDH8Hr9fbkc/rPChGQ9DvFNHUGdvWTSL3tDkmfSk+EdzHU1rwZxHAhGVz2SlwLGWs7zS9YrpbF7xyuOT7GhR9ZRH4Ef1fPxHjztTIbu74mC+PdPf/Odm/ john.doe@example.net
```

## Einbinden der authorized_keys-Datei in das EcoSystem

Um die `authorized_keys`-Datei in das EcoSystem einzubinden, geht man für VMware-Workstation-VMs folgendermaßen vor:

- Erstellen einer neuen VM durch das Importieren des CES-Images
- Einbinden des Ordners, der die `authorized_keys`-Datei enthält, als Shared Folder
    - Siehe "Einstellungen" der VM -> "Optionen"-Reiter -> "Shared Folders"
    - Aktivierung von "Shared Folders" und Hinzufügen des Ordners mit einem Namen
- Neuen Eintrag in der `/etc/fstab`
  erstellen: `.host:/NameDesSharedFolders /etc/ces fuse.vmhgfs-fuse defaults,allow_other,uid=1000 0 0`
- Reboot des Systems oder Mounten des Shared Folders via `sudo mount -a`
