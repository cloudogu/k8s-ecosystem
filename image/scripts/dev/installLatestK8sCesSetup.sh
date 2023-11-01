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
helm_registry_host=${11}
helm_registry_schema=${12}
helm_registry_plain_http=${13}
kube_ctx_name=${14}

# set environment for helm and kubectl
export KUBECONFIG="${HOME}/.kube/$kube_ctx_name"

# Apply the setup resources to the current namespace.
applyResources() {
  echo "Applying resources for setup..."
  # Remove hard coded registry.cloudogu.com if helm 3.13 is released. Use then --plain-http flag with the proxy registry.
  helm registry login registry.cloudogu.com --username "${helm_registry_username}" --password "${helm_registry_password}"

  # use generated .setup.json if it exists, otherwise use setup.json
  SETUP_JSON=image/scripts/dev/setup.json
  if [ -f image/scripts/dev/.setup.json ]; then
    SETUP_JSON=image/scripts/dev/.setup.json
  fi

  helm upgrade -i k8s-ces-setup "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-ces-setup" \
    --namespace="${CES_NAMESPACE}" \
    --set-file=setup_json=${SETUP_JSON} \
    --set=dogu_registry_secret.url="${dogu_registry_url}" \
    --set=dogu_registry_secret.username="${dogu_registry_username}" \
    --set=dogu_registry_secret.password="${dogu_registry_password//,/\\,}" \
    --set=docker_registry_secret.url="${image_registry_url}" \
    --set=docker_registry_secret.username="${image_registry_username}" \
    --set=docker_registry_secret.password="${image_registry_password//,/\\,}" \
    --set=helm_registry_secret.host="${helm_registry_host}" \
    --set=helm_registry_secret.schema="${helm_registry_schema}" \
    --set=helm_registry_secret.plainHttp="${helm_registry_plain_http}" \
    --set=helm_registry_secret.username="${helm_registry_username}" \
    --set=helm_registry_secret.password="${helm_registry_password//,/\\,}" \
    --set=components.k8s-longhorn.version="latest" \
    --set=components.k8s-longhorn.helmRepositoryNamespace="k8s" \
    --set=components.k8s-longhorn.deployNamespace="longhorn-system"
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

echo "**** Executing installLatestK8sCesSetup.sh..."

checkIfSetupIsInstalled
applyResources

echo "**** Finished installLatestK8sCesSetup.sh"
