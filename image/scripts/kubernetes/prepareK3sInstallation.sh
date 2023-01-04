#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k3sVersion=v1.24.9+k3s1
longhornVersion=v1.4.0
k3sBinarySHA256SUM=2ca446c6180675b39d241d14cf7f5a329f366e929fb35b0388e303657ad6e006
k3sImagesTarSHA256SUM=3d426f64dd3e791d02d309e5c0d45089675e2382d831cc473ce4bd2ac20d6ab5

echo "Downloading k3s binary..."
wget -q "https://github.com/k3s-io/k3s/releases/download/${k3sVersion}/k3s"
echo "${k3sBinarySHA256SUM} k3s" | sha256sum --check

echo "Downloading k3s images archive..."
wget -q "https://github.com/k3s-io/k3s/releases/download/${k3sVersion}/k3s-airgap-images-amd64.tar"
echo "${k3sImagesTarSHA256SUM} k3s-airgap-images-amd64.tar" | sha256sum --check

echo "Downloading k3s install script..."
wget -q "https://get.k3s.io/" -O install.sh
chmod +x install.sh

echo "Downloading longhorn deployment yaml..."
wget -q https://raw.githubusercontent.com/longhorn/longhorn/${longhornVersion}/deploy/longhorn.yaml -O longhorn.yaml

echo "Moving k3s binary to /usr/local/bin and making it executable..."
mv k3s /usr/local/bin/k3s
chmod 754 /usr/local/bin/k3s

echo "Copying k3s image archive to k3s images folder..."
mkdir -p /var/lib/rancher/k3s/agent/images/
mv ./k3s-airgap-images-amd64.tar /var/lib/rancher/k3s/agent/images/

echo "Writing k3s version to /var/lib/rancher/k3s/agent/images/k3sVersion..."
echo "${k3sVersion}" > /var/lib/rancher/k3s/agent/images/k3sVersion