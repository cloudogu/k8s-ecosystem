#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "Setting KUBECONFIG in /home/vagrant/.bashrc and /root/.bashrc..."
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
sudo sh -c 'echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc'

echo "Checking cluster connection..."
for (( i = 1; i <=10; i++ )); do
    if ! kubectl get nodes > /dev/null; then
        echo "Cluster not available yet (${i})"
        sleep 2
    else
        break
    fi
done
