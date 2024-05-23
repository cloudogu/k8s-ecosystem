#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source k3s-util.sh

nodeIp=${1}
nodeExternalIp=${2}
flannelInterface=${3}
mainNodeIp=${4}
mainNodePort=${5}
k3sToken=${6}
username=${7}
nodeLabels="${8}"
nodeTaints="${9}"

k3sVersion=$(cat /var/lib/rancher/k3s/agent/images/k3sVersion)

nodeLabelOptions=$(getOptionListForList "--node-label" "${nodeLabels}")
nodeTaintOptions=$(getOptionListForList "--node-taint" "${nodeTaints}")

echo "Installing k3s-agent ${k3sVersion}..."
INSTALL_K3S_SKIP_DOWNLOAD=true \
INSTALL_K3S_VERSION=${k3sVersion} \
K3S_KUBECONFIG_MODE="644" \
K3S_URL="https://${mainNodeIp}:${mainNodePort}" \
INSTALL_K3S_EXEC="${nodeLabelOptions}
 ${nodeTaintOptions}
 --node-external-ip=${nodeExternalIp}
 --node-ip=${nodeIp}
 --flannel-iface=${flannelInterface}" \
K3S_TOKEN="${k3sToken}" \
/home/"${username}"/install.sh
