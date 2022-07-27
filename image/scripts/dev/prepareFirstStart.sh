#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This is usually done by the k3s-conf service, but doesn't work at first start
K3S_SYSTEMD_ENV_DIR=/etc/systemd/system
K3S_SYSTEMD_ENV_FILE="${K3S_SYSTEMD_ENV_DIR}/k3s.service.env"
K3S_SYSTEMD_SERVICE_FILE="${K3S_SYSTEMD_ENV_DIR}/k3s.service"
externalIpAddress=192.168.56.2
echo "Replacing IP in ${K3S_SYSTEMD_ENV_FILE} with ${externalIpAddress}..."
sed -i "s|^\(K3S_EXTERNAL_IP\)=.\+$|\1='${externalIpAddress}'|g" "${K3S_SYSTEMD_ENV_FILE}"
echo "Replacing IP in ${K3S_SYSTEMD_SERVICE_FILE} with ${externalIpAddress}..."
sed -i "s|\(--node[-a-z]*-ip\)=.*$|\1=${externalIpAddress}' \\\|g" "${K3S_SYSTEMD_SERVICE_FILE}"
echo "Replacing flannel-iface in ${K3S_SYSTEMD_SERVICE_FILE} with enp0s8..."
sed -i "s|\(--flannel-iface\)=.*$|\1=enp0s8' \\\|g" "${K3S_SYSTEMD_SERVICE_FILE}"
