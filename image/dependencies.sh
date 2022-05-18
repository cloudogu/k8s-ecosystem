#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "**** Begin installing nfs-common and jq"
apt-get install -y nfs-common jq
echo "**** End installing nfs-common and jq"
