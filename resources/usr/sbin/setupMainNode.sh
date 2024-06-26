#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source k3s-util.sh

nodeIp=${1}
nodeExternalIp=${2}
flannelInterface=${3}
k3sToken=${4}
username=${5}
nodeLabels="${6}"
nodeTaints="${7}"
imageGcLowThreshold=${8}
imageGcHighThreshold=${9}

k3sVersion=$(cat /var/lib/rancher/k3s/agent/images/k3sVersion)

echo "Re-syncing VM time to avoid certificate time errors..."
if systemctl is-enabled --quiet chrony; then
  echo "Restarting chrony..."
  systemctl restart chrony.service
else
  echo "Restarting systemd-timesyncd..."
  systemctl restart systemd-timesyncd.service
fi

nodeLabelOptions=$(getOptionListForList "--node-label" "${nodeLabels}")
nodeTaintOptions=$(getOptionListForList "--node-taint" "${nodeTaints}")

echo "Installing k3s ${k3sVersion}..."
INSTALL_K3S_SKIP_DOWNLOAD=true \
INSTALL_K3S_VERSION=${k3sVersion} \
K3S_KUBECONFIG_MODE="644" \
K3S_TOKEN=${k3sToken} \
K3S_EXTERNAL_IP="${nodeExternalIp}" \
INSTALL_K3S_EXEC="${nodeLabelOptions}
 ${nodeTaintOptions}
 --disable local-storage
 --node-label svccontroller.k3s.cattle.io/enablelb=true
 --disable traefik
 --node-external-ip=${nodeExternalIp}
 --node-ip=${nodeIp}
 --flannel-iface=${flannelInterface}
 --kubelet-arg=image-gc-low-threshold=${imageGcLowThreshold}
 --kubelet-arg=image-gc-high-threshold=${imageGcHighThreshold}" \
/home/"${username}"/install.sh

echo "Configuring KUBECONFIG..."
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/environment
chmod 660 /etc/rancher/k3s/k3s.yaml
