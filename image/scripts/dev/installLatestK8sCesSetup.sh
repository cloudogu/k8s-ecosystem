#!/bin/bash
# This file is responsible to install the latest ces setup.
set -o errexit
set -o nounset
set -o pipefail

CES_NAMESPACE=${1}
helm_repository_namespace=${2}
dogu_registry_username=${3}
dogu_registry_password=${4}
dogu_registry_url=${5}
image_registry_username=${6}
image_registry_password=${7}
image_registry_url=${8}
helm_registry_username=${9}
helm_registry_password=${10}
helm_registry_url=${11}

# set environment for helm and kubectl
export KUBECONFIG=~/.kube/config:~/.kube/k3ces.local

# Apply the setup resources to the current namespace.
applyResources() {
  echo "Applying resources for setup..."
  helm registry login "${helm_registry_url}" --username "${helm_registry_username}" --password "${helm_registry_password}"
  helm upgrade -i k8s-ces-setup "oci://${helm_registry_url}/${helm_repository_namespace}/k8s-ces-setup" \
    --namespace="${CES_NAMESPACE}" \
    --set-file=setup_json=image/scripts/dev/setup.json \
    --set=dogu_registry_secret.url="${dogu_registry_url}" \
    --set=dogu_registry_secret.username="${dogu_registry_username}" \
    --set=dogu_registry_secret.password="${dogu_registry_password//,/\\,}" \
    --set=docker_registry_secret.url="${image_registry_url}" \
    --set=docker_registry_secret.username="${image_registry_username}" \
    --set=docker_registry_secret.password="${image_registry_password//,/\\,}" \
    --set=helm_registry_secret.url="${helm_registry_url}" \
    --set=helm_registry_secret.username="${helm_registry_username}" \
    --set=helm_registry_secret.password="${helm_registry_password//,/\\,}"
}


checkIfSetupIsInstalled() {
    echo "Check if setup is already installed or executed"
    if kubectl --namespace "${CES_NAMESPACE}" get deployments k8s-ces-setup | grep -q k8s-ces-setup
    then
      echo "Setup is already installed: Found k8s-ces-setup deployment"
      exit 0
    fi

    if kubectl --namespace "${CES_NAMESPACE}" get deployments k8s-dogu-operator-controller-manager | grep -q k8s-dogu-operator
    then
      echo "Setup is already executed: Found k8s-dogu-operator deployment"
      exit 0
    fi
}

waitForLonghorn() {
  echo "Waiting for longhorn to start up"

  # wait for pods to spawn
  sleep 10s

  for (( i = 0; i <=19; i++ )); do
      local sleepInterval=10
      if kubectl -n longhorn-system get pods -o custom-columns=READY-true:status.containerStatuses[*].ready | grep false > /dev/null; then
          echo "Some longhorn pods are still starting ($((i * sleepInterval))s)"
          sleep $sleepInterval
      else
          echo "Longhorn has started"
          break
      fi
  done
}

echo "**** Executing installLatestK8sCesSetup.sh..."

checkIfSetupIsInstalled
# Wait for longhorn pods again because on additional nodes longhorn pods need some time again to start.
waitForLonghorn
applyResources

echo "**** Finished installLatestK8sCesSetup.sh"
