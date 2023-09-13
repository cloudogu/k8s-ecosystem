#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This file executes settings and installations only on the K8s main node.
export DOCKER_REGISTRY_DIR=/vagrant/image/scripts/dev/docker-registry

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
  local deploymentTargetPath="${DOCKER_REGISTRY_DIR}/docker-registry.yaml"

  kubectl --namespace "${targetNamespace}" apply -f "${deploymentTargetPath}"
}

function runInstallRegistry() {
  local fqdn="${1}"
  local targetNamespace="${2}"
  local registryProxyRemoteUrl="${3}"
  local registryProxyUsername="${4}"
  local registryProxyPassword="${5}"

  echo "Installing Docker registry with FQDN=${fqdn} and namespace=${targetNamespace}"

  createRegistryProxySecret "${registryProxyRemoteUrl}" "${registryProxyUsername}" "${registryProxyPassword}" ${targetNamespace}
  deployRegistry "${targetNamespace}"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runInstallRegistry "$@"
fi
