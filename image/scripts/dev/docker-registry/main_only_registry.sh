#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This file executes settings and installations only on the K8s main node.
export DOCKER_REGISTRY_DIR=/vagrant/image/scripts/dev/docker-registry

function deployRegistry() {
  local targetNamespace="${1}"
  local deploymentTargetPath="${DOCKER_REGISTRY_DIR}/docker-registry.yaml"

  kubectl --namespace "${targetNamespace}" apply -f "${deploymentTargetPath}"
}

function runInstallRegistry() {
  local fqdn="${1}"
  local targetNamespace="${2}"

  echo "Installing Docker registry with FQDN=${fqdn} and namespace=${targetNamespace}"

  deployRegistry "${targetNamespace}"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runInstallRegistry "$@"
fi
