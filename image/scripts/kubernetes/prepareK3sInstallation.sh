#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k3sVersion=v1.37.2+k3s1
k3sBinarySHA256SUM=265b3ee6a3198ef14033c63ef46cbb32370d83795199fb6d1b01f21575eddbda
k3sImagesTarSHA256SUM=98edf22b01e7237b122cc78c7cd560001491678a1ff18a7af654f1461bd30a53

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
