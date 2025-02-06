#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ./scripts/util.sh

gardenKubeConfig="$1"
gardenNamespace="$2"
shootName="$3"
cesNamespace="$4"

export SHOOT_CA_CERT_FILE="/tmp/${shootName}-cacert"
export SHOOT_CERT_FILE="/tmp/${shootName}-cert"
export SHOOT_KEY_FILE="/tmp/${shootName}-key"
export SHOOT_KUBE_CONFIG="/tmp/${shootName}-shoot-kubeconfig.yaml"

getShootKubeConfig "${gardenKubeConfig}" "${gardenNamespace}" "${shootName}"

server=$(extractKubeConfig "${SHOOT_KUBE_CONFIG}")

curl -s --cacert "${SHOOT_CA_CERT_FILE}" --cert "${SHOOT_CERT_FILE}" --key "${SHOOT_KEY_FILE}" "${server}/api/v1/namespaces/${cesNamespace}/services/ces-loadbalancer" -X PATCH -d '[{"op": "add", "path": "/metadata/annotations", "value": {"loadbalancer.openstack.org/keep-floatingip" : "false"}}]' -H "Content-Type: application/json-patch+json"

# Sleep here to give the loadbalancer reconcile time to release the public ip.
sleep 10

removeAuthFiles
