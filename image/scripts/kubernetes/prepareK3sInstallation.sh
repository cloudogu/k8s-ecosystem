#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k3sVersion=v1.24.9+k3s1
k3sBinarySHA256SUM=4dd997c611739fb5c540519492751bdf8751dfa9afbd331df6c18fd8f982efb4
k3sImagesTarSHA256SUM=bfb5ae74056c41a8a1b7ebd3941b600135307d2892b073e0f58585e3e276aa63

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