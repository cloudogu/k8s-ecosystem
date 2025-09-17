#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k9sVersion=v0.50.9
k9sTarSHA256SUM=5e625efa26c3e14256cf29d242179b32129183b549937ec62d0ad9be1bfe2ca4
installDir=/usr/local/bin/
k9sFileName="k9s_Linux_amd64.tar.gz"

echo "Installing k9s to ${installDir}..."
wget -q "https://github.com/derailed/k9s/releases/download/${k9sVersion}/${k9sFileName}"
echo "${k9sTarSHA256SUM} ${k9sFileName}" | sha256sum --check
mkdir -p "${installDir}"
tar xf "${k9sFileName}" -C "${installDir}"
rm "${k9sFileName}"
