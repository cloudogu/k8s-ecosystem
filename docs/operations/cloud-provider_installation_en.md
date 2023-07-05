# Installation in other cloud providers

The installation scripts to install the CES as a POC in a deployed Kubernetes cluster can be found in the `externalcloud` folder.

## Preparation

### .env.sh

The installation requires information about the kubectl context and the dogu registries.
These can be provided as environment variables via an `.env.sh` file in the installation folder.

```shell
# example .env.sh
export kube_context="ces-multinode"
export dogu_registry_username="username".
export dogu_registry_password="secret-password".
export dogu_registry_url="https://dogu.cloudogu.com/api/v2/dogus"
export image_registry_username="username"
export image_registry_password="secret-password"
export image_registry_email="test@test.de"
```

### setup.json

In the `setup.json` the configuration for the CES can be adjusted.
Among other things, the FQDN and the admin user can be configured here.

### Cloud provider

Notes on individual cloud providers can be found here:
- [GoogleCloud](cloud-provider_installation_google_cloud_en.md)
- [Azure AKS](cloud-provider_installation_azure_aks_en.md)
- [Plusserver](cloud-provider_installation_plusserver_en.md)

## Installation

The installation is started by executing the `install.sh` file:

```shell
./install.sh
```

> Longhorn: To install Longhorn, `./installLonghorn.sh` must be commented into `install.sh`.

## Rework

### FQDN change

If an IP address is used as FQDN and it was not specified correctly in `setup.json` before installation, it must be changed afterwards.
If the LoadBalancer service `nginx-ingress-exposed-443` has been assigned an IP, the script `syncFQDN.sh` can be executed for this purpose.

- It reads the external IP from the k8s service
- In the "etcd-client"-deployment the IP is set as FQDN `etcdctl set /config/_global/fqdn <IP>`.
- Afterwards the self-signed certificate is automatically recreated by `k8s-service-discovery`
- Finally, all pods of the Dogus are restarted

### Postgresql

The postgres container has a different routing table. The dogu only processes the exact one. 0.0.0.0 is ignored.
To fix this, the script `fixPostgresql.sh` must be executed. Contents of the script:

- Editing the subnet mask of `/var/lib/postgresql/pg_hba.conf` in the container network. For example, from `32` to `16`:
```
      # container networks
      host all all 10.244.0.0/16 password
```


- Reload the config:
  `su postgres -c "pg_ctl reload"`