# Dev Box with k3d

This document describes a lightweight local development alternative to the Vagrant-based dev box. Instead of starting a VM, the Kubernetes cluster runs directly in Docker via `k3d`.

## Current scope

The `k3d` path is intended to manage multiple local CES instances through a small wrapper script. It reuses the existing [`installEcosystem.sh`](../../image/scripts/dev/installEcosystem.sh) directly against the matching `kubeconfig`.

Compared to the Vagrant setup, this path currently does not try to reproduce:

- the basebox image
- the node configuration from `nodeconfig/k3sConfig.json`
- the in-cluster proxy registry workflow for component and chart development

If you need the existing proxy registry workflow on ports `30098` and `30099`, the Vagrant setup remains the more complete option.

## Prerequisites

- `docker`
- `k3d`
- `kubectl`
- `helm`
- `curl`
- `jq`
- `yq`

## One-time configuration

From the repository root:

```shell
cp k3d/config.env.template k3d/config.env
```

Then fill in the credentials in `k3d/config.env`.

Important notes:

- The file contains shared defaults for all local `k3d` ecosystems.
- Longhorn is disabled by default for `k3d`, because `k3d` already provides the `local-path` storage class.
- The scripts add an internal CoreDNS entry so pods resolve the CES FQDN to the `ces-loadbalancer` service.
- The existing `.blueprint-override.yaml` behavior still works because the same blueprint mechanism is used.
- If the CES should be updated on repeated bootstrap runs, set `FORCE_UPGRADE_ECOSYSTEM="true"` in `k3d/config.env`.

## Create a new ecosystem

The manager creates the `k3d` cluster, writes a dedicated `kubeconfig` and then installs the CES:

```shell
k3d/ecosystem.sh create my-ces
```

The script assigns these values automatically:

- FQDN: `my-ces.k3ces.localdomain`
- kubeconfig: `~/.kube/my-ces.k3ces.localdomain`
- host IP: next free loopback IP from `127.0.0.0/24`
- Kubernetes API port: next free port starting at `6550`
- merge into the default kubeconfig: `~/.kube/config` without automatically switching the current context
- default namespace in the context: `ecosystem`
- `/etc/hosts` entry via `sudo` as long as `MANAGE_HOSTS_FILE="true"`

To see which IP a managed ecosystem uses, run:

```shell
k3d/ecosystem.sh list
```

## Manage ecosystems

```shell
k3d/ecosystem.sh list
k3d/ecosystem.sh open my-ces
k3d/ecosystem.sh stop my-ces
k3d/ecosystem.sh start my-ces
k3d/ecosystem.sh delete my-ces
```

`start` and `stop` call the matching `k3d` commands directly. `delete` also removes the managed `kubeconfig` and the generated instance config below `k3d/environments/`.

`open` launches `https://<fqdn>` in the host's default browser.

By default the scripts also:

- merge the context into `~/.kube/config`
- update or remove the matching `/etc/hosts` entry

You can control this behavior in `k3d/config.env`:

- `MERGE_DEFAULT_KUBECONFIG`
- `SWITCH_DEFAULT_KUBECONFIG_CONTEXT`
- `DEFAULT_KUBECONFIG_PATH`
- `MANAGE_HOSTS_FILE`

## Manual low-level scripts

The manager uses these helper scripts internally:

- `k3d/cluster.sh` for cluster creation and kubeconfig handling
- `k3d/install.sh` for CES bootstrap on an existing cluster

If you want to rerun the bootstrap for an existing ecosystem, call:

```shell
k3d/install.sh k3d/environments/my-ces.env
```
