#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k3sVersion=v1.33.4+k3s1
k3sBinarySHA256SUM=10da34c350ab8a02e4513a6021046db9e9afecc31bae77419bc6444cbd7b1400
k3sImagesTarSHA256SUM=3d694301e8534783990b41d6a6ef251cd72348af7219473d08f676e2689200ac

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
