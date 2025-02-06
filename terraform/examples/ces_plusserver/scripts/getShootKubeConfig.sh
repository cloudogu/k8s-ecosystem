#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

gardenNamespace="$1"
shootName="$2"
gardenKubeConfig="$3"
outputShootKubeConfig="$4"

# TODO maybe replace with kubectl wait
sleep 10


#KUBECONFIG="${gardenKubeConfig}" kubectl create \
#-f <(printf '{"spec":{"expirationSeconds":600}}') \
#--raw "/apis/core.gardener.cloud/v1beta1/namespaces/${gardenNamespace}/shoots/${shootName}/adminkubeconfig" | \
#jq -r ".status.kubeconfig" | \
#base64 -d > "${outputShootKubeConfig}"

# The following lines replace the above kubectl command to create a kube config for the given shoot cluster.
# We do this because in the coder environment there is no kubectl or jq/yq.
# And instead of other environments like google for plusserver there is no terraform provider to provision a kubernetes cluster
# that returns the kube config.
# We have to apply a "shoot resource" with a regular kubectl provider (see terraform files) and after that create the
# following subresource "adminkubeconfig" with this nullresource.

server=$(grep server "${gardenKubeConfig}" | sed 's/server://g' | awk '{$1=$1};1')
token=$(grep -A 1 token "${gardenKubeConfig}" | tail -1 | awk '{$1=$1};1')
certFile="./shoot_cert"
grep -A 1 certificate-authority-data "${gardenKubeConfig}" | tail -1 | awk '{$1=$1};1' | base64 --decode > "${certFile}"

# TODO Reduce expiration time
response=$(curl -s "${server}/apis/core.gardener.cloud/v1beta1/namespaces/${gardenNamespace}/shoots/${shootName}/adminkubeconfig" -H "Authorization: Bearer ${token}" --cacert "${certFile}" -X POST -d '{"spec":{"expirationSeconds":6000}}' -H "Content-Type: application/json")

echo "${response}" | grep '"kubeconfig":' | sed 's/"kubeconfig"://g' | awk '{$1=$1};1' | sed 's/"//g' | sed 's/,//g' | base64 --decode > "${outputShootKubeConfig}"

rm -f "${certFile}"
