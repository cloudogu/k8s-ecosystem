#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "Installing ces-setup..." 
kubectl --namespace ecosystem create configmap k8s-ces-setup-json --from-file=/vagrant/setup_installation/setup.json
kubectl apply -f /vagrant/setup_installation/k8s-ces-setup-config.yaml
kubectl --namespace ecosystem apply -f /vagrant/setup_installation/k8s-ces-setup.patched.yaml

echo "ces-setup is running automatically now (based on setup.json)..."
