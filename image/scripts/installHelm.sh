#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

helmVersion=v3.15.2
helmTarSHA256SUM=2694b91c3e501cff57caf650e639604a274645f61af2ea4d601677b746b44fe2
installDir=/usr/local/bin

echo "Installing helm to ${installDir}..."
wget -q https://get.helm.sh/helm-${helmVersion}-linux-amd64.tar.gz
echo "${helmTarSHA256SUM} helm-${helmVersion}-linux-amd64.tar.gz" | sha256sum --check
mkdir -p "${installDir}"
tar -zxvf helm-${helmVersion}-linux-amd64.tar.gz --strip-components=1 -C "${installDir}" linux-amd64/helm
rm helm-${helmVersion}-linux-amd64.tar.gz
