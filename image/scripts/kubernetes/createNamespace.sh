#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "Create namespace [${CES_NAMESPACE}] in k3s cluster..."
kubectl create namespace "${CES_NAMESPACE}"
