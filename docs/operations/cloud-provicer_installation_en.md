# Installation in other cloud providers
The installation scripts to install the CES in a deployed Kubernetes cluster can be found in the `externalcloud` folder.

## Preparation

### .env.sh
The installation requires information about the kubectl context and the dogu registry.
These can be provided as environment variables via an `.env.sh` file in the installation folder.

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

### setup.json
In the `setup.json` the configuration for the CES can be adjusted.
Among other things, the FQDN and the admin user can be configured here.

### Cloud-Provider
- [GoogleCloud](cloud-provicer_installation_google_cloud_en.md)
- [Azure AKS](cloud-provicer_installation_azure_aks_en.md)

## Installation
The installation is started by executing the `install.sh` file:

```shell
./install.sh
```

> Longhorn: To install Longhorn, `./installLonghorn.sh` must be commented into `install.sh`.

## Adjustments

### FQDN change
If an IP address is used as FQDN and it was not correctly specified in the `setup.json` before installation, it must be changed afterwards:
- The External IP can be read out from the k8s service for the IngressController
- In the "etcd-client"-deployment the adjustment of the FQDN can be done `etcdctl set /config/_global/fqdn <IP>`.
- Afterwards the self-signed certificate will be recreated automatically
- Additionally the CAS and all other already installed Dogus should be restarted

### Postgresql

- Postgres container has a different routing table. The dogu only processes the exact one. 0.0.0.0 is ignored.
  - Must be fixed in the dogu
  - Edit `/var/lib/postgresql/pg_hba.conf` and adjust the subnetmask of the container network. For example from `24` to `16`:
      ```
      # container networks
      host    all             all             10.244.0.0/16  password
      ```

  - Reload the config:
    - `su - postgres`
    - `PGDATA=/var/lib/postgresql pg_ctl reload`