#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

k9sVersion=v0.50.16
k9sTarSHA256SUM=bda09dc030a08987fe2b3bed678b15b52f23d6705e872d561932d4ca07db7818
installDir=/usr/local/bin/
k9sFileName="k9s_Linux_amd64.tar.gz"

echo "Installing k9s to ${installDir}..."
wget -q "https://github.com/derailed/k9s/releases/download/${k9sVersion}/${k9sFileName}"
echo "${k9sTarSHA256SUM} ${k9sFileName}" | sha256sum --check
mkdir -p "${installDir}"
tar xf "${k9sFileName}" -C "${installDir}"
rm "${k9sFileName}"
