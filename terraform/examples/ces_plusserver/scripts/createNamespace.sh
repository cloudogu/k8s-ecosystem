#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

gardenKubeConfig="$1"
gardenNamespace="$2"
shootName="$3"
namespaceName="$4"

export SHOOT_CA_CERT_FILE="/tmp/${shootName}-cacert"
export SHOOT_CERT_FILE="/tmp/${shootName}-cert"
export SHOOT_KEY_FILE="/tmp/${shootName}-key"
export SHOOT_KUBE_CONFIG="/tmp/${shootName}-shoot-kubeconfig.yaml"

source ./scripts/util.sh

getShootKubeConfig "${gardenKubeConfig}" "${gardenNamespace}" "${shootName}"

server=$(extractKubeConfig "${SHOOT_KUBE_CONFIG}")

curl -q --cacert "${SHOOT_CA_CERT_FILE}" --cert "${SHOOT_CERT_FILE}" --key "${SHOOT_KEY_FILE}" "${server}/api/v1/namespaces/" -X POST -d "{\"metadata\":{\"name\":\"${namespaceName}\"}}" -H "Content-Type: application/json" || true

removeAuthFiles



