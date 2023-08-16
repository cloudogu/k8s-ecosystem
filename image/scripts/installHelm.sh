#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

helmVersion=v3.12.3
helmTarSHA256SUM=1b2313cd198d45eab00cc37c38f6b1ca0a948ba279c29e322bdf426d406129b5
installDir=/usr/local/bin

echo "Installing helm to ${installDir}..."
wget -q https://get.helm.sh/helm-${helmVersion}-linux-amd64.tar.gz
echo "${helmTarSHA256SUM} helm-${helmVersion}-linux-amd64.tar.gz" | sha256sum --check
mkdir -p "${installDir}"
tar xf helm-${helmVersion}-linux-amd64.tar.gz -C "${installDir}"
rm helm-${helmVersion}-linux-amd64.tar.gz
