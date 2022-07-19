#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

workerIpAddress="${1}"
serverIpAddress="${2}"
serverPort="${3}"
k3s_token="${4}"

default_network_interface=$(ip -4 route ls | grep 192.168.56 | grep -Po '(?<=dev )(\S+)')

echo "**** Begin installing k3s worker node"
curl -sfL https://get.k3s.io | \
INSTALL_K3S_VERSION=v1.24.2+k3s2 \
K3S_KUBECONFIG_MODE="644" \
K3S_URL="https://${serverIpAddress}:${serverPort}" \
INSTALL_K3S_EXEC="--node-external-ip=${workerIpAddress}
 --node-ip=${workerIpAddress}
 --flannel-iface=${default_network_interface}" \
K3S_TOKEN="${k3s_token}" \
sh -
# Increase virtual address space for sonar dogu.
# see https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html
sysctl -w vm.max_map_count=262144
echo "**** End installing k3s worker node"
