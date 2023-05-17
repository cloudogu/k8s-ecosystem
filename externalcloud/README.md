# Installation in anderen Cloud-Providern

## Vorbedingungen
Eine `.env.sh` muss erstellt sein:

```shell
# example .env.sh
export kube_context="ces-multinode"
export dogu_registry_username="username"
export dogu_registry_password="secret-password"
export dogu_registry_url="https://dogu.cloudogu.com/api/v2/dogus"
export image_registry_username="username"
export image_registry_password="secret-password"
export image_registry_email="test@test.de"
```

Hinweise zu den Cloud-Providern befinden sich in den jeweiligen Readmes:
- [GoogleCloud](GoogleCloud.md)
- [Azure AKS](Azure_AKS.md)

## Ausführung

```shell
./install.sh
```

> Longhorn: Um Longhorn zu installieren, muss `./installLonghorn.sh` in der `install.sh` einkommentiert werden.