# Test LOP-IDP

To test the new LOP-IDP and postfix components, copy the appropriate values patches like so:
```bash
cp docs/development/.lop-idp-blueprint-override.yaml .blueprint-override.yaml
cp docs/development/.lop-idp-ecosystem-core-values-patch.yaml .ecosystem-core-values-patch.yaml
```

If you use mkcert, you have to set the `certificate/type` key to `external` in `.blueprint-override.yaml`.
