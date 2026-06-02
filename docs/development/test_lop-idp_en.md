# Test LOP-IDP

To test the new LOP-IDP and postfix components, copy the appropriate values patches like so:
```bash
cp docs/development/.lop-idp-blueprint-override.yaml .blueprint-override.yaml
cp docs/development/.lop-idp-ecosystem-core-values-patch.yaml .ecosystem-core-values-patch.yaml
```

If you use mkcert, you have to set the `certificate/type` key to `external` in `.blueprint-override.yaml`.

Due to [a bug in ecosystem-core](https://github.com/cloudogu/ecosystem-core/issues/64), a configmap with the name `postfix-config` will already exist and cause an error during the installation of postfix. Until it is fixed, it can for now be circumvented by deleting the configmap.