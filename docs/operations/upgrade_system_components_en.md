# Updating system components

## k3s

### Manual upgrade

> Info: The main nodes must always be updated first.

#### Installation script

An upgrade can be carried out by re-executing the installation script:

`INSTALL_K3S_VERSION=vX.Y.Z-rc1 /home/<user>/install.sh <EXISTING_K3S_ARGS>`

For current arguments see: [setupMainNode.sh](../../resources/usr/sbin/setupMainNode.sh)

For more information see: [Rancher documentation](https://docs.k3s.io/upgrades/manual#upgrade-k3s-using-the-installation-script)

#### Binary

It is also possible to upgrade k3s by swapping the binary:

See: [Rancher documentation](https://docs.k3s.io/upgrades/manual#manually-upgrade-k3s-using-the-binary)

### Automated upgrade

For automated upgrades, the [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) from Rancher could be used.
This controller is highly privileged and offers with its `Plan` custom resource to upgrade system components (also e.g. APT packages).

The Cloudogu EcoSystem does not currently offer a component for this method.

## Info

### Restart of k3s main nodes

`sudo systemctl restart k3s`

### Restart k3s agent nodes

`sudo systemctl restart k3s-agent`