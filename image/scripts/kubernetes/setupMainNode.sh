#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# re-sync VM time to avoid certificate time errors
systemctl restart systemd-timesyncd.service

DEFAULT_NETWORK_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')
export DEFAULT_NETWORK_INTERFACE

EXTERNAL_IP_ADDRESS=$(ip addr show "${DEFAULT_NETWORK_INTERFACE}" | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
export EXTERNAL_IP_ADDRESS

echo "The default network interface of this machine has been detected as: ${DEFAULT_NETWORK_INTERFACE}"
echo "The external ip address of this machine has been detected as: ${EXTERNAL_IP_ADDRESS}"
echo "Installing k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.23.6+k3s1 K3S_KUBECONFIG_MODE="644" \
K3S_EXTERNAL_IP="${EXTERNAL_IP_ADDRESS}" INSTALL_K3S_EXEC="--disable local-storage --node-label svccontroller.k3s.cattle.io/enablelb=true
--no-deploy=traefik --node-external-ip=${EXTERNAL_IP_ADDRESS} --node-ip=${EXTERNAL_IP_ADDRESS} --flannel-iface=${DEFAULT_NETWORK_INTERFACE}" K3S_TOKEN="${K3S_TOKEN}" sh -

echo "Increasing virtual address space for sonar dogu..."
# see https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html
sysctl -w vm.max_map_count=262144
