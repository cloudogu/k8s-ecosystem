#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

nodeIp=${1}
nodeExternalIp=${2}
flannelInterface=${3}
mainNodeIp=${4}
mainNodePort=${5}
k3sToken=${6}
username=${7}

k3sVersion=$(cat /var/lib/rancher/k3s/agent/images/k3sVersion)

echo "Installing k3s-agent ${k3sVersion}..."
INSTALL_K3S_SKIP_DOWNLOAD=true \
INSTALL_K3S_VERSION=${k3sVersion} \
K3S_KUBECONFIG_MODE="644" \
K3S_URL="https://${mainNodeIp}:${mainNodePort}" \
INSTALL_K3S_EXEC="--node-external-ip=${nodeExternalIp}
 --node-ip=${nodeIp}
 --flannel-iface=${flannelInterface}" \
K3S_TOKEN="${k3sToken}" \
/home/"${username}"/install.sh
