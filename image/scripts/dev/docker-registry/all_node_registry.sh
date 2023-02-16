#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This file executes settings and installations per K8s node.
# This file must run as root.
export ETC_HOSTS=/etc/hosts
DOCKER_REGISTRY_PORT=30099
FQDN="${1}"
HOST_IP="${2}"

function addEtcHostsEntryForRegistry() {
  local etcHostsExitCode=0
  grep "${HOST_IP}\s\+${FQDN}" "${ETC_HOSTS}" > /dev/null || etcHostsExitCode=$?

  if [[ ${etcHostsExitCode} == 0 ]]; then
    echo "Found registry entry in ${ETC_HOSTS}"
  elif [[ ${etcHostsExitCode} == 1 ]]; then
    echo "Adding ${ETC_HOSTS} entry for registry"
    echo "${HOST_IP}    ${FQDN}" >> "${ETC_HOSTS}"
  else
    echo "ERROR: Detecting ${ETC_HOSTS} entry exited with exit code ${etcHostsExitCode}"
    echo "Pushing container images may fail!"
    exit 1
  fi
}

function echoPushHint() {
  echo "INFO: You can test image pushing from your development computer to the cluster registry like this:
    1. add ${FQDN}:${DOCKER_REGISTRY_PORT} to /etc/docker/daemon.json's insecure registry list
    2. docker pull ubuntu
    3. docker tag ubuntu ${FQDN}:${DOCKER_REGISTRY_PORT}/ubuntu
    4. docker push ${FQDN}:${DOCKER_REGISTRY_PORT}/ubuntu
"
}

function runSetNode() {
  addEtcHostsEntryForRegistry
  echoPushHint
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runSetNode "$@"
fi
