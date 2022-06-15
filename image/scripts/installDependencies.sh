#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "**** Begin installing nfs-common, docker and jq"
apt-get install -y nfs-common jq docker.io
echo "**** End installing nfs-common, docker and jq"
