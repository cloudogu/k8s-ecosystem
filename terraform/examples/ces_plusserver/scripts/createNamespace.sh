#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ./scripts/util.sh

shootKubeConfig="$1"
namespaceName="$2"

server=$(extractKubeConfig "${shootKubeConfig}")

# TODO Check if namespace already exists?
curl --cacert cacert --cert cert --key key "${server}/api/v1/namespaces/" -X POST -d "{\"metadata\":{\"name\":\"${namespaceName}\"}}" -H "Content-Type: application/json" || true

removeAuthFiles



