#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k3sVersion=v1.30.1+k3s1
k3sBinarySHA256SUM=39a5057fb49bf576a45c32ef3ef63bff448252d4d25c6c41b8dcc5e48e278bf5
k3sImagesTarSHA256SUM=ac278be0ae99f496f8c561b84698a53fc51567bb882fab1357b0a0eb741c006d

echo "Downloading k3s binary..."
wget -q "https://github.com/k3s-io/k3s/releases/download/${k3sVersion}/k3s"
echo "${k3sBinarySHA256SUM} k3s" | sha256sum --check

echo "Downloading k3s images archive..."
wget -q "https://github.com/k3s-io/k3s/releases/download/${k3sVersion}/k3s-airgap-images-amd64.tar"
echo "${k3sImagesTarSHA256SUM} k3s-airgap-images-amd64.tar" | sha256sum --check

echo "Downloading k3s install script..."
wget -q "https://get.k3s.io/" -O install.sh
chmod +x install.sh

echo "Moving k3s binary to /usr/local/bin and making it executable..."
mv k3s /usr/local/bin/k3s
chmod 754 /usr/local/bin/k3s

echo "Copying k3s image archive to k3s images folder..."
mkdir -p /var/lib/rancher/k3s/agent/images/
mv ./k3s-airgap-images-amd64.tar /var/lib/rancher/k3s/agent/images/

echo "Writing k3s version to /var/lib/rancher/k3s/agent/images/k3sVersion..."
echo "${k3sVersion}" > /var/lib/rancher/k3s/agent/images/k3sVersion