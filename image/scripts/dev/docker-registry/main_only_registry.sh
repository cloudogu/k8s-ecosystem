#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This script executes settings and installations only on the K8s main node.

registryHaSharedSecret=JLdfd343MnfsI
proxyRegistryHaSharedSecret=LFD83nmdfHD

function createRegistryProxySecret() {
  local registryProxyRemoteUrl="${1}"
  local registryProxyUsername="${2}"
  local registryProxyPassword="${3}"
  local targetNamespace="${4}"

  kubectl --namespace "${targetNamespace}" create secret generic docker-registry-secret --from-literal=proxyRemoteUrl="${registryProxyRemoteUrl}" --from-literal=haSharedSecret="${registryHaSharedSecret}" --from-literal=proxyHaSharedSecret="${proxyRegistryHaSharedSecret}" --from-literal=proxyUsername="${registryProxyUsername}" --from-literal=proxyPassword="${registryProxyPassword}"
}

function deployRegistry() {
  local targetNamespace="${1}"
  local imageRegistryYaml="${2}"

  kubectl --namespace "${targetNamespace}" apply -f "${imageRegistryYaml}"
}

function runInstallRegistry() {
  local fqdn="${1}"
  local targetNamespace="${2}"
  local registryProxyRemoteUrl="${3}"
  local registryProxyUsername="${4}"
  local registryProxyPassword="${5}"
  local imageRegistryYaml="${6}"

  echo "fqdn: ${1}"
  echo "targetNamespace: ${2}"
  echo "registryProxyRemoteUrl: ${3}"
  echo "registryProxyUsername: ${4}"
  echo "registryProxyPassword: ${5}"
  echo "imageRegistryYaml: ${6}"

  echo "Installing Docker registry with FQDN=${fqdn} and namespace=${targetNamespace}"

  createRegistryProxySecret "${registryProxyRemoteUrl}" "${registryProxyUsername}" "${registryProxyPassword}" "${targetNamespace}"
  deployRegistry "${targetNamespace}" "${imageRegistryYaml}"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runInstallRegistry "$@"
fi
