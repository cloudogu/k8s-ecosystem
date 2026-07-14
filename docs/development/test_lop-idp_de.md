# LOP-IDP testen

Um die neuen LOP-IDP- und Postfix-Komponenten zu testen, kopieren Sie die entsprechenden Values-Patches wie folgt:
```bash
cp docs/development/.lop-idp-blueprint-override.yaml .blueprint-override.yaml
cp docs/development/.lop-idp-ecosystem-core-values-patch.yaml .ecosystem-core-values-patch.yaml
```

Wenn Sie mkcert verwenden, müssen Sie den Schlüssel `certificate/type` in der Datei `.blueprint-override.yaml` auf `external` setzen.

Aufgrund eines [Fehlers in ecosystem-core](https://github.com/cloudogu/ecosystem-core/issues/64) existiert bereits eine ConfigMap mit dem Namen `postfix-config`, was bei der Installation von Postfix zu einem Fehler führt. Bis dieser Fehler behoben ist, lässt sich das Problem vorerst umgehen, indem Sie die ConfigMap löschen.