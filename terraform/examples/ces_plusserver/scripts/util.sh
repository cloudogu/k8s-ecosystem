#!/bin/bash

set -o nounset

# getShootKubeConfig extracts auth information from the given gardener config and create a kube config for the shoot cluster.
# It writes the config in "${SHOOT_KUBE_CONFIG}" path. Callers should assign this variable before usage.

# Equivalent kubectl command:
# KUBECONFIG="${gardenKubeConfig}" kubectl create \
# -f <(printf '{"spec":{"expirationSeconds":600}}') \
# --raw "/apis/core.gardener.cloud/v1beta1/namespaces/${gardenNamespace}/shoots/${shootName}/adminkubeconfig" | \
# jq -r ".status.kubeconfig" | \
# base64 -d > "${outputShootKubeConfig}"

# The following lines replace the above kubectl command to create a kube config for the given shoot cluster.
# This is useful to create resources in a cluster that are not tracked in the terraform state.
# We do this in this way because the coder environment has no kubectl or jq/yq.
getShootKubeConfig() {
  local gardenKubeConfig=$1 gardenNamespace=$2 shootName=$3

  local server token gardenerCaCertFile
  server=$(grep server "${gardenKubeConfig}" | sed 's/server://g' | awk '{$1=$1};1')
  token=$(grep -A 1 token "${gardenKubeConfig}" | tail -1 | awk '{$1=$1};1')
  gardenerCaCertFile="/tmp/gardenerCaCert"
  grep -A 1 certificate-authority-data "${gardenKubeConfig}" | tail -1 | awk '{$1=$1};1' | base64 --decode > "${gardenerCaCertFile}"

  local response
  response=$(curl -s "${server}/apis/core.gardener.cloud/v1beta1/namespaces/${gardenNamespace}/shoots/${shootName}/adminkubeconfig" -H "Authorization: Bearer ${token}" --cacert "${gardenerCaCertFile}" -X POST -d '{"spec":{"expirationSeconds":600}}' -H "Content-Type: application/json")

  echo "${response}" | grep '"kubeconfig":' | sed 's/"kubeconfig"://g' | awk '{$1=$1};1' | sed 's/"//g' | sed 's/,//g' | base64 --decode > "${SHOOT_KUBE_CONFIG}"

  rm -f "${gardenerCaCertFile}"
}


# extractKubeConfig decodes authentication data from the given kubeconfig and writes them to files in order to use them with curl.
# Callers have to assign SHOOT_CA_CERT_FILE SHOOT_CERT_FILE and SHOOT_KEY_FILE before usage.
# Remove the auth files after usage with removeAuthFiles.
extractKubeConfig() {
  grep -A 1 certificate-authority-data "$1" | head -1 | sed 's/certificate-authority-data://g' | awk '{$1=$1};1' | base64 -d > "${SHOOT_CA_CERT_FILE}"
  grep client-certificate-data "$1" | sed 's/client-certificate-data://g' | awk '{$1=$1};1' | base64 -d > "${SHOOT_CERT_FILE}"
  grep client-key-data "$1" | sed 's/client-key-data://g' | awk '{$1=$1};1' | base64 -d > "${SHOOT_KEY_FILE}"

  grep server "$1" | head -1 | sed 's/server://g' | awk '{$1=$1};1'
}

removeAuthFiles() {
  rm -f "${SHOOT_CA_CERT_FILE}" "${SHOOT_CERT_FILE}" "${SHOOT_KEY_FILE}" "${SHOOT_KUBE_CONFIG}"
}

