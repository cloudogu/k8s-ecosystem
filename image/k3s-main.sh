#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "**** Begin installing k3s main node"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.23.3+k3s1 K3S_KUBECONFIG_MODE="644" \
K3S_EXTERNAL_IP="${EXTERNAL_IP_ADDRESS}" INSTALL_K3S_EXEC="--disable local-storage --node-label svccontroller.k3s.cattle.io/enablelb=true
--no-deploy=traefik --node-external-ip=${EXTERNAL_IP_ADDRESS} --node-ip=${EXTERNAL_IP_ADDRESS} --flannel-iface=eth1" K3S_TOKEN="${K3S_TOKEN}" sh -
# Increase virtual address space for sonar dogu.
# see https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html
sysctl -w vm.max_map_count=262144
echo "**** End installing k3s main node"
