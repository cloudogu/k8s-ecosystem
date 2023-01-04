#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k9sVersion=v0.26.7
k9sTarSHA256SUM=f774bb75045e361e17a4f267491c5ec66f41db7bffd996859ffb1465420af249
installDir=/usr/local/bin/

echo "Installing k9s to ${installDir}..."
wget -q https://github.com/derailed/k9s/releases/download/${k9sVersion}/k9s_Linux_x86_64.tar.gz
echo "${k9sTarSHA256SUM} k9s_Linux_x86_64.tar.gz" | sha256sum --check
mkdir -p "${installDir}"
tar xf k9s_Linux_x86_64.tar.gz -C "${installDir}"
echo "Configuring KUBECONFIG..."
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/"${USERNAME}"/.bashrc
