#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k9sVersion=v0.32.5
k9sTarSHA256SUM=33c31bf5feba292b59b8dabe5547cb52ab565521ee5619b52eb4bd4bf226cea3
installDir=/usr/local/bin/
k9sFileName="k9s_Linux_amd64.tar.gz"

echo "Installing k9s to ${installDir}..."
wget -q "https://github.com/derailed/k9s/releases/download/${k9sVersion}/${k9sFileName}"
echo "${k9sTarSHA256SUM} ${k9sFileName}" | sha256sum --check
mkdir -p "${installDir}"
tar xf "${k9sFileName}" -C "${installDir}"
rm "${k9sFileName}"
