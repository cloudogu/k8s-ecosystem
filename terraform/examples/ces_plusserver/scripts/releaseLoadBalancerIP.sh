#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ./scripts/util.sh

shootKubeConfig="$1"
namespace="$2"

echo "DEBUG: ${shootKubeConfig}"
echo "DEBUG: ${namespace}"

server=$(extractKubeConfig "${shootKubeConfig}")

curl --cacert cacert --cert cert --key key "${server}/api/v1/namespaces/${namespace}/services/ces-loadbalancer" -X PATCH -d '[{"op": "add", "path": "/metadata/annotations", "value": {"loadbalancer.openstack.org/keep-floatingip" : "false"}}]' -H "Content-Type: application/json-patch+json"

sleep 10

removeAuthFiles
