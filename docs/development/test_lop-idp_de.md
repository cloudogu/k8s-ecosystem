# LOP-IDP testen

Um die neuen LOP-IDP- und Postfix-Komponenten zu testen, kopieren Sie die entsprechenden Values-Patches wie folgt:
```bash
cp docs/development/.lop-idp-blueprint-override.yaml .blueprint-override.yaml
cp docs/development/.lop-idp-ecosystem-core-values-patch.yaml .ecosystem-core-values-patch.yaml
```

Wenn Sie mkcert verwenden, müssen Sie den Schlüssel `certificate/type` in der Datei `.blueprint-override.yaml` auf `external` setzen.
