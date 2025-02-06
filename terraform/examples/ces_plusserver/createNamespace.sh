#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

shootKubeConfig="$1"
namespace="$2"

server=$(grep server "${shootKubeConfig}" | head -1 | sed 's/server://g' | awk '{$1=$1};1')
grep -A 1 certificate-authority-data "${shootKubeConfig}" | head -1 | sed 's/certificate-authority-data://g' | awk '{$1=$1};1' | base64 -d > cacert
grep client-certificate-data "${shootKubeConfig}" | sed 's/client-certificate-data://g' | awk '{$1=$1};1' | base64 -d > cert
grep client-key-data "${shootKubeConfig}" | sed 's/client-key-data://g' | awk '{$1=$1};1' | base64 -d > key

# TODO Check if namespace already exists?
curl --cacert cacert --cert cert --key key "${server}/api/v1/namespaces/" -X POST -d "{\"metadata\":{\"name\":\"${namespace}\"}}" -H "Content-Type: application/json" || true

rm -f cacert cert key



