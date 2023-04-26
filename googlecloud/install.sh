#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

kubectl config set-context gke_ces-operations-internal_europe-west3-a_ces-multinode
./createNamespace.sh "ecosystem"
./installLonghorn.sh
