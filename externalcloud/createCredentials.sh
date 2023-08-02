#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail


echo "Generating registry.cloudogu.com secret..."
kubectl create secret docker-registry k8s-dogu-operator-docker-registry --namespace=ecosystem --docker-server="$4" --docker-username="$5" --docker-password="$6" --docker-email="$7" || true
kubectl create secret generic k8s-dogu-operator-dogu-registry --namespace=ecosystem --from-literal=username="$1" --from-literal=password="$2" --from-literal=endpoint="$3" || true
