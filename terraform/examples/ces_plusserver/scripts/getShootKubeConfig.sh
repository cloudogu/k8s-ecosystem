#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

gardenNamespace="$1"
shootName="$2"
gardenKubeConfig="$3"
outputShootKubeConfig="$4"

sleep 10

server=$(grep server "${gardenKubeConfig}" | sed 's/server://g' | awk '{$1=$1};1')
token=$(grep -A 1 token "${gardenKubeConfig}" | tail -1 | awk '{$1=$1};1')
certFile="./shoot_cert"
grep -A 1 certificate-authority-data "${gardenKubeConfig}" | tail -1 | awk '{$1=$1};1' | base64 --decode > "${certFile}"

response=$(curl -s "${server}/apis/core.gardener.cloud/v1beta1/namespaces/${gardenNamespace}/shoots/${shootName}/adminkubeconfig" -H "Authorization: Bearer ${token}" --cacert "${certFile}" -X POST -d '{"spec":{"expirationSeconds":6000}}' -H "Content-Type: application/json")

echo "${response}" | grep '"kubeconfig":' | sed 's/"kubeconfig"://g' | awk '{$1=$1};1' | sed 's/"//g' | sed 's/,//g' | base64 --decode > "${outputShootKubeConfig}"

rm -f "${certFile}"
