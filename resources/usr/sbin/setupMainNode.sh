#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

nodeIp=${1}
nodeExternalIp=${2}
flannelInterface=${3}
k3sToken=${4}
username=${5}

k3sVersion=$(cat /var/lib/rancher/k3s/agent/images/k3sVersion)

echo "Re-syncing VM time to avoid certificate time errors..."
if systemctl is-enabled --quiet chrony; then
  echo "Restarting chrony..."
  systemctl restart chrony.service
else
  echo "Restarting systemd-timesyncd..."
  systemctl restart systemd-timesyncd.service
fi

echo "Installing k3s ${k3sVersion}..."
INSTALL_K3S_SKIP_DOWNLOAD=true \
INSTALL_K3S_VERSION=${k3sVersion} \
K3S_KUBECONFIG_MODE="644" \
K3S_TOKEN=${k3sToken} \
K3S_EXTERNAL_IP="${nodeExternalIp}" \
INSTALL_K3S_EXEC="--disable local-storage
 --node-label svccontroller.k3s.cattle.io/enablelb=true
 --no-deploy=traefik
 --node-external-ip=${nodeExternalIp}
 --node-ip=${nodeIp}
 --flannel-iface=${flannelInterface}" \
/home/"${username}"/install.sh

echo "Configuring KUBECONFIG..."
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/environment
chmod 660 /etc/rancher/k3s/k3s.yaml
