#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

cesNamespace="${1}"

if kubectl get namespace | grep "${cesNamespace}" ; then
    echo "Namespace ${cesNamespace} already exists. Done."
    exit 0
fi

echo "Creating namespace [${cesNamespace}] in k3s cluster..."
kubectl create namespace "${cesNamespace}"
