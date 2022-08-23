#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This file executes settings and installations per K8s node.
# This file must run as root.
export REGISTRY_ETC_DIR=/etc/rancher/k3s
export DOCKER_REGISTRY_DIR=/vagrant/image/scripts/dev/docker-registry
export REGISTRY_TEMP_DIR=/vagrant/tmp
export ETC_HOSTS=/etc/hosts
DOCKER_REGISTRY_PORT=30099

function registerRegistryWithK3s() {
  local fqdn="${1}"
  local fqdnTemplateVar="REGISTRY_IDENTIFIER"
  local registryTemplate="${DOCKER_REGISTRY_DIR}/k3s_registry.tmpl.yaml"
  local registryTemplateRendered="${REGISTRY_TEMP_DIR}/k3s_registry.yaml"
  local registryTargetPath="${REGISTRY_ETC_DIR}/registries.yaml"

  mkdir -p "${REGISTRY_TEMP_DIR}"
  mkdir -p "${REGISTRY_ETC_DIR}"

  echo "Registering Registry with K3s"
  sed "s/${fqdnTemplateVar}/${fqdn}:${DOCKER_REGISTRY_PORT}/g" "${registryTemplate}" > "${registryTemplateRendered}"

  cp "${registryTemplateRendered}" "${registryTargetPath}"
}

function addEtcHostsEntryForRegistry() {
  local fqdn="${1}"

  local etcHostsExitCode=0
  grep "192\.168\.56\.2\s\+${fqdn}" "${ETC_HOSTS}" > /dev/null || etcHostsExitCode=$?

  if [[ ${etcHostsExitCode} == 0 ]]; then
    echo "Found registry entry in /etc/hosts"
  elif [[ ${etcHostsExitCode} == 1 ]]; then
    echo "Adding /etc/hosts entry for registry"
    echo "192.168.56.2    ${fqdn}" >> "${ETC_HOSTS}"
  else
    echo "ERROR: Detecting /etc/hosts entry exited with exit code ${etcHostsExitCode}"
    echo "Pushing container images may fail!"
    exit 1
  fi
}

function echoPushHint() {
  local fqdn="${1}"
  echo "INFO: You can test image pushing from your development computer to the cluster registry like this:
    1. add ${fqdn}:${DOCKER_REGISTRY_PORT} to /etc/docker/daemon.json's insecure registry list
    2. docker pull ubuntu
    3. docker tag ubuntu ${fqdn}:${DOCKER_REGISTRY_PORT}/ubuntu
    4. docker push ${fqdn}:${DOCKER_REGISTRY_PORT}/ubuntu
"
}

function restartK3s() {
  echo "Restarting k3s to apply registry.yaml..."
  systemctl restart k3s || systemctl restart k3s-agent
}

function runSetNode() {
  local fqdn="${1}"

  registerRegistryWithK3s "${fqdn}"
  addEtcHostsEntryForRegistry "${fqdn}"
  echoPushHint "${fqdn}"
  restartK3s
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runSetNode "$@"
fi
