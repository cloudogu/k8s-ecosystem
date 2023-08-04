# Setup of a Cloudogu EcoSystem in Kubernetes.

This document describes in detail how to install the Cloudogu EcoSystem in a Kubernetes cluster.
Trivially, a Kubernetes cluster is required for the installation.

If running a cluster on an external cloud provider is not an option, Cloudogu provides an OVF,
which is used for main **and** worker nodes. In it, the Kubernetes implementation 
[`k3s`](https://docs.k3s.io/) with [`longhorn`](https://longhorn.io/docs/) as the storage provisioner will be used. However, the cloud providers' internal provisioners are recommended.

This document shows which components need to be installed and configured. A distinction is made between the setup of a
Kubernetes cluster and that of the actual Cloudogu EcoSystem within the cluster.
This is followed by a bullet-point list of prerequisites to prepare for an installation.
This is followed by the actual installation instructions with notes for various operating environments such as Google or Microsoft.

## 1. What to install/configure?

### Kubernetes cluster setup with Cloudogu K3s image.

This option is suitable if external cloud provider is not an option. Otherwise, you can continue from section 2.

- `k3sConfig.json`
  - A configuration containing information about all nodes of the cluster. It is read by a service that configures `k3s`.
  - This file contains:
    - Tokens as a shared secret for mutual node login in the cluster,
    - IP addresses of the machines used, and
    - registry configurations
  - The file must be mounted in **each** node.
- `authorized_keys`
  - For debugging, it can be useful to gain SSH access to each node. This requires a list of accepted keys to be mounted in each node.

### Cloudogu EcoSystem Setup

- Namespace: `ecosystem`
- Secret: `k8s-dogu-operator-docker-registry` - contains credentials to the image registry used.
- Secret: `k8s-dogu-operator-dogu-registry` - contains credentials to the used dogu registry.
- Configmap: `k8s-ces-setup-config` - contains configuration for setup among other versions of CES components e.g. Dogu operator to be installed.
- Configmap: `k8s-ces-setup-json` - contains configuration for setup among others FQDN or Dogu versions.
- Setup application: contains deployment, service, roles etc. to start the setup process.

## 2. Preparation

### What information is needed.

- Docker registry credentials.
  - URL: registry.cloudogu.com
  - Username
  - password
  - Email address
- Dogu registry credentials
  - URL: https://dogu.cloudogu.com/api/v2/dogus
  - Username
  - password
  - Email address

## 3. Installation instructions

If the Cloudogu EcoSystem is to be installed on an existing cluster, proceed with [Cloudogu EcoSystem Installation](#cloudogu-ecosystem-installation).

### Cluster Setup with K3s Image

For OVF deployment, please contact hello@cloudogu.com.

#### Create Nodes

- Create all nodes of the future cluster from the provided image, but do not start them yet.

#### Install k3sConfig.json

- For each node, there must be a complete entry in the `nodes` section.
- The Docker registry (harbor) must be configured in the `docker-registry-configuration` section.
  - `k3s-token` must be re-selected.
  - IPs and interfaces of the nodes must be adjusted accordingly.
- The `k3sConfig.json` must be mounted in each node in `/etc/ces/nodeconfig/k3sConfig.json`.

Example for a cluster of one main node and three worker nodes:

```json
{
   "ces-namespace":"ecosystem",
   "k3s-token":"SuPeR_secure123!TOKEN-Changeme",
   "nodes":[
      {
         "name":"ces-main",
         "isMainNode":true,
         "node-ip":"192.168.2.101",
         "node-external-ip":"192.168.2.101",
         "flannel-iface":"eth0"
      },
      {
         "name":"ces-worker-0",
         "node-ip":"192.168.2.96",
         "node-external-ip":"192.168.2.96",
         "flannel-iface":"eth0"
      },
      {
         "name":"ces-worker-1",
         "node-ip":"192.168.2.91",
         "node-external-ip":"192.168.2.91",
         "flannel-iface":"eth0"
      },
      {
         "name":"ces-worker-2",
         "node-ip":"192.168.2.102",
         "node-external-ip":"192.168.2.102",
         "flannel-iface":"eth0"
      }
   ]
}
```

If an air-gapped environment is used where docker and dogu registry are mirrored,
a mirror for the Docker registry must be configured here.

Example of registry setup for mirrored images:

```json
{
   "ces-namespace":"ecosystem",
   "k3s-token":"SuPeR_secure123!TOKEN-Changeme",
   "nodes":[
     ...
   ],
   "docker-registry-configuration":{
      "mirrors":{
         "docker.io":{
            "endpoint":[
               "https://<registry-url>"
            ]
         }
      },
      "configs":{
         "<registry-url>":{
            "auth":{
               "username":"user1",
               "password":"password1"
            }
         }
      }
   }
}
```

- Detailed documentation for `k3sConfig.json` can be found [here](https://github.com/cloudogu/k8s-ecosystem/blob/develop/docs/operations/configuring_main_and_worker_nodes_de.md).

#### Mount SSH pub key(s)

- Write all public keys to be used in the nodes for SSH access into a file `authorized_keys`.
- Customize each node of the cluster to mount the `authorized_keys` file to `/etc/ces/authorized_keys` on startup.
- More information can be found [here](https://github.com/cloudogu/k8s-ecosystem/blob/develop/docs/operations/ssh_authentication_de.md).

Example:

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDY0nVMmCeczF8jLAwnw3PNGMMAlqskpw8lfJuZeTIrAklIIeVqXmaHaCDbC+Z+/WYtp/5A9H8V6MDz7pMyrTCnm8g6nKZ0J/kH+kP8iT9f1d2V78AG1P3v6R19UeT8h3926bB/IJGmnzo53gnfdV+YhSEwsIGFI3ikzjc0GOZBAvhCLPo6WXAbcvM5+qVTFUjkQwi6lQBjtS/cIZJrcB9J9bLNJbait5itaXLyLy52Igt8dQbzB5hnvlBwUuFHnt0agXF0yxb+VVRzF0BVZ0rE0MKwCiG/mwbspIDOhuMj5DwtRiSC0LtNCn9V46cuDy1lrsUvO2g1mo3ptbhEAxv+UAStbDKkgSvKDfK3Q0AdLE6+AgZ/EehcRQvo10W5lY6JOm5PcHstFQLy4g660IiOrxrSN5HCZmRzeU49vT4o3tYxXsxSebxvumOmmnHlZUczZbRbEiSJ5L7RLRhQpJ4adkGuPWEyXXYsQtlgOlmBUZnEm9N8oaNIlknW5lUV4ZyRMAL7VdMgvwZDaqWgl1JZpp9Np3WKWizzuOOZm6jlZW3Sbsyr8Lw3SZXYSCU03gx+YZFGk+1zmwvtCp86i7gzH6lpami8mAHfEWVqaZoHWBlCU35gqaUscvWEJ7KMtQNCdHV8tMEE5IFSfigXgQjfsiqj6v+detsN+uN31PepxQ== SSHuser123
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCJi7dJnW9zB3m5iakfUwmntYLahA82WqYKM3f9VQhbpwI93zBD2SPrvH02TtEVgGvyW3oR7RMVbAOf0YEe5F6GM3qxL8r1uhitrOqblDCAz8xyVz1GfWy3v+5hMXyN3/yFpTmm8QK1V9xdIKdMcxGn5CdEpMHSODs1X7CIxs2fZ2Kw4kzCOY064+wfwGpnaJhbABpNnEudLAHkphZWSB0wF0kVrcU4GJaDH8Hr9fbkc/rPChGQ9DvFNHUGdvWTSL3tDkmfSk+EdzHU1rwZxHAhGVz2SlwLGWs7zS9YrpbF7xyuOT7GhR9ZRH4Ef1fPxHjztTIbu74mC+PdPf/Odm/ john.doe@example.net
```

#### Start up nodes

- Starting with the main node, boot all nodes.
- The installation routines that initialize the Kubernetes cluster can be tracked via `journalctl -f -u k3s-conf.service`.
- Whether all nodes in the cluster are available can be seen via `kubectl get nodes`.
- Whether all pods have been started successfully can be seen with `kubectl get pods`.
  - Alternatively, the graphical tool `k9s` can be used. General information about graphical Kubernetes management in the terminal k9s is available here: [https://k9scli.io/](https://k9scli.io/)

#### Set Kubeconfig

To be able to work on the host for further steps, it is useful to copy the cluster configurations:
- The configuration is available as yaml file in the VM under `/etc/rancher/k3s/k3s.yaml`.
- Using the cluster configuration on the host
  - Save the cluster configuration on the host, e.g. as `~/.kube/k3s.yaml`.
  - Set configuration, e.g. via `export KUBECONFIG=~/.kube/k3s.yaml`.
  - Test the configuration, e.g. via `kubectl get all --all-namespaces`.

This Kubeconfig can also be used to access the cluster from other machines.

### Cloudogu EcoSystem Installation

#### Download the scripts

If the Cloudogu EcoSystem is based on an OVF in an air-gapped environment, this script download section should be skipped and the existing provisioning scripts should be used instead.

```bash
installDir="ces_scripts" && \
mkdir -p ${installDir} && \
wget -P ${installDir} https://raw.githubusercontent.com/cloudogu/k8s-ecosystem/develop/externalcloud/install.sh && \
wget -P ${installDir} https://raw.githubusercontent.com/cloudogu/k8s-ecosystem/develop/externalcloud/createNamespace.sh && \
wget -P ${installDir} https://raw.githubusercontent.com/cloudogu/k8s-ecosystem/develop/externalcloud/createCredentials.sh && \
wget -P ${installDir} https://raw.githubusercontent.com/cloudogu/k8s-ecosystem/develop/externalcloud/installLonghorn.sh && \
wget -P ${installDir} https://raw.githubusercontent.com/cloudogu/k8s-ecosystem/develop/externalcloud/installLatestK8sCesSetup.sh && \
chmod +x ${installDir}/*.sh
```

#### Configuration of the scripts

##### Credentials

A `.env.sh` file must be created in the same directory:

```bash
export kube_context="k3ces.local"
export dogu_registry_url="https://dogu.cloudogu.com/api/v2/dogus"
export dogu_registry_username=""
export dogu_registry_password=""
export image_registry_url="registry.cloudogu.com"
export image_registry_username=""
export image_registry_password=""
export image_registry_email=""
```

Show available Kube-contexts:

- `kubectl config get-contexts`

#### setup.json

A `setup.json` file must be created in the same directory:

Example:

```json
{
  "naming": {
    "fqdn": "",
    "domain": "k3ces.local",
    "certificateType": "selfsigned",
    "relayHost": "your-mail-relay-host",
    "completed": true,
    "useInternalIp": false,
    "internalIp": ""
  },
  "dogus": {
    "defaultDogu": "cas",
    "install": [
      "official/ldap",
      "official/postfix",
      "k8s/nginx-static",
      "k8s/nginx-ingress",
      "official/cas"
    ],
    "completed": true
  },
  "admin": {
    "username": "admin",
    "mail": "admin@admin.admin",
    "password": "changeme",
    "adminGroup": "cesAdmin",
    "completed": true,
    "adminMember": true,
    "sendWelcomeMail": false
  },
  "userBackend": {
    "dsType": "embedded",
    "server": "",
    "attributeID": "uid",
    "attributeGivenName": "",
    "attributeSurname": "",
    "attributeFullname": "cn",
    "attributeMail": "mail",
    "attributeGroup": "memberOf",
    "baseDN": "",
    "searchFilter": "(objectClass=person)",
    "connectionDN": "",
    "password": "",
    "host": "ldap",
    "port": "389",
    "loginID": "",
    "loginPassword": "",
    "encryption": "",
    "completed": true,
    "groupBaseDN": "",
    "groupSearchFilter": "",
    "groupAttributeName": "",
    "groupAttributeDescription": "",
    "groupAttributeMember": ""
  }
}
```

#### Installation

Start the installation with the aforementioned `./install.sh`.

The setup will start automatically if `completed: true` is in each section of `setup.json`.
Otherwise the setup can be started manually:

`curl -I --request POST --url http://<any-node-ip>:30080/api/v1/setup`

> Info: If the setup process aborts because an invalid value was specified in `setup.json`, the configmap `k8s-setup-config` must be deleted after correcting the `setup.json`.
> After this, the setup can be started again.

The Cloudogu EcoSystem can be deleted **completely** from the cluster with the following commands (the created registry credentials remain unaffected):

- Delete dogus
```bash
kubectl delete dogus -l app=ces -n ecosystem
```

- Delete remaining resources
```bash
kubectl patch cm tcp-services -p '{"metadata":{"finalizers":null}}' --type=merge -n ecosystem || true \
&& kubectl patch cm udp-services -p '{"metadata":{"finalizers":null}}' --type=merge -n ecosystem || true \
&& kubectl delete statefulsets,deploy,secrets,cm,svc,sa,rolebindings,roles,clusterrolebindings,clusterroles,cronjob,pvc,pv --ignore-not-found -l app=ces -n ecosystem
```

## 4. notes for different infrastructures and cloud providers

### Using mirrored registries

If mirrored registries are used, it is quite possible that all Docker images are located in a
subproject in the registry (here, for example, `organization`).

Example structure:
```
example.com/
├── organization <-
│   ├── k8s
│   │   ╰── k8s-dogu-operator
│   │       ╰── 0.1.0
│   ├── official
│   │   ╰── cas
│   │       ╰── 0.1.0
│   ├── premium
│   ╰── other namespace
```

In this case, a rewrite must be created for the container configuration of `k3s` so that images
such as `example.com/longhorn/manager` can be obtained e.g. from `example.com/organization/longhorn/manager`.

Example `k3sConfig.json`:

```json
{
   "docker-registry-configuration":{
      "mirrors":{
         "docker.io":{
            "endpoint":[
               "https://example.com"
            ],
            "rewrite":{
               "^(.*)$": "organization/$1"
            }
         }
      }
   }
}
```

### Mirrored registries use self-signed certificates with K3s

Self-signed certificates must be made known to `k3s` on the respective nodes and operators.

#### Store self-signed certificates in k3s

Example `k3sConfig.json`:

```json
{
  "ces-namespace":"ecosystem",
  "k3s-token":"SuPeR_secure123!TOKEN-Changeme",
  "nodes":[
    ...
  ],
  "docker-registry-configuration":{
    "mirrors":{
      "docker.io":{
        "endpoint":[
          "https://<registry-url>"
        ]
      }
    },
    "configs":{
      "<registry-url>":{
        "auth":{
          ...
        },
        "tls": {
          "ca_file": "/etc/ssl/certs/your.pem"
        }
      }
    }
  }
}
```

After a new certificate creation, the services `k3s` (on the main node) or `k3s-agent` must be restarted:

```bash
# ssh into the respective machine
sudo systemctl restart k3s
sudo systemctl restart k3s-agent
```

#### #### Store self-signed certificates in cluster-state

```bash
kubectl --namespace ecosystem create secret generic docker-registry-cert --from-file=docker-registry-cert.pem=<cert_name>.pem
kubectl --namespace ecosystem create secret generic dogu-registry-cert --from-file=dogu-registry-cert.pem=<cert_name>.pem
```

- More information can be found [here](https://github.com/cloudogu/k8s-dogu-operator/blob/develop/docs/operations/using_self_signed_certs_de.md).

### Notes for different cloud providers

Since cloud provider environments may differ, it is possible that additional configurations may be necessary for the operation of the CES. In the following links you can find hints for the operation at Google, Microsoft and Plusserver:

- [Google](cloud-provider_installation_google_cloud_en.md)
- [Microsoft](cloud-provider_installation_azure_aks_en.md)
- [Plusserver](cloud-provider_installation_plusserver_en.md)

