Im Folgenden finden Sie einige Best Practices für Bash-Skripte.

## Beginnen Sie mit einem Shebang

Die erste Zeile in einem Bash-Skript sollte lauten:

```bash
#!/bin/bash
```

## Fügen Sie eine Beschreibung hinzu

Fügen Sie am Anfang des Skripts eine Beschreibung ein, wenn dessen Zweck nicht bereits durch den Namen oder Ähnliches eindeutig ersichtlich ist.

## Fehlerbehandlung

Verwenden sie die folgenden „set“-Zeilen, damit das Skript bei Fehlern beendet wird, anstatt diese zu ignorieren:
````bash
set -o errexit
````
Weist Bash an, das Skript sofort zu beenden, wenn ein Befehl einen Exit-Status ungleich Null hat. Sie können „|| true“ zu Befehlen hinzufügen, bei denen ein Fehlschlag bzw. ein Exit-Code ungleich Null zulässig ist.
````bash
set -o nounset
````
Wenn diese Option gesetzt ist, führt der Verweis auf eine Variable, die Sie zuvor nicht definiert haben – mit Ausnahme von $* und $@ –, zu einem Fehler und bewirkt, dass das Programm sofort beendet wird.
````bash
set -o pipefail
````
Diese Einstellung verhindert, dass Fehler in einer Pipeline verdeckt werden. Wenn ein Befehl in einer Pipeline fehlschlägt, wird dessen Rückgabecode als Rückgabecode der gesamten Pipeline verwendet.


## Fehlerinformationen an stderr ausgeben

Geben Sie alle Fehlerdaten an stderr aus, indem Sie
````bash
echo "this is an error" >&2
````

vor oder hinter „echo“-Befehle setzen.

## Variablen mit ${} verwenden

Verwenden Sie beim Verweisen auf Variablen geschweifte Klammern anstelle von nur $VARIABLE. Dieser Standard verhindert Probleme bei der Verwendung der Bash-Variablen.

## apt-get automatisieren

Die folgenden Zeilen sind nützlich, wenn Software automatisch mit apt-get installiert wird:
````bash
apt-get --assume-yes (oder -y) ...
````

Automatische Antwort „yes“ auf Fragen von apt-get
````bash
DEBIAN_FRONTEND=noninteractive apt-get ...
````

Sorgt dafür, dass das Frontend überhaupt nicht mit Ihnen interagiert und bei allen Fragen die Standardantworten verwendet werden.

## Temporäre Daten entfernen

Nachdem Sie Installationsdaten an einen temporären Speicherort kopiert und ausgeführt haben, vergessen Sie nicht, diese zu entfernen, wenn Ihre Installation erfolgreich war.

## Weitere Informationen

[Inoffizielle Beschreibung des Bash-Strict-Modus](http://redsymbol.net/articles/unofficial-bash-strict-mode/)

[Bewährte Vorgehensweisen beim Schreiben von Bash-Skripten](http://kvz.io/blog/2013/11/21/bash-best-practices/)
