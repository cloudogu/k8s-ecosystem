#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

installDir=/usr/local/bin/

echo "Installing k9s to ${installDir}..."
wget -q https://github.com/derailed/k9s/releases/download/v0.26.6/k9s_Linux_x86_64.tar.gz
mkdir -p "${installDir}"
tar xf k9s_Linux_x86_64.tar.gz -C "${installDir}"
echo "Configuring KUBECONFIG..."
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/"${USERNAME}"/.bashrc
