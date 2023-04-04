#!/bin/bash
# This file is responsible to install the latest ces setup.
set -o errexit
set -o nounset
set -o pipefail

CES_NAMESPACE=${1}
TEMP_DIR=""
CES_SETUP_RELEASE_CONFIG_YAML=https://raw.githubusercontent.com/cloudogu/k8s-ces-setup/develop/k8s/k8s-ces-setup-config.yaml
CES_SETUP_RELEASE_YAML=https://raw.githubusercontent.com/cloudogu/k8s-ces-setup/develop/k8s/k8s-ces-setup.yaml

# Download the latest kubernetes resource yamls for the setup from the GitHub repository.
downloadLatestSetupReleaseResources() {
  echo "Downloading the latest k8s-ces-setup..."
  curl -s "${CES_SETUP_RELEASE_YAML}" -o "${TEMP_DIR}"/setup.yaml

  echo "Downloading the latest release configuration of the k8s-ces-setup..."
  curl -s "${CES_SETUP_RELEASE_CONFIG_YAML}" -o "${TEMP_DIR}"/config.yaml
}

# Replace the namespace placeholder with the actual namespace of the cluster.
templateNamespace() {
  echo "Templating namespace ${CES_NAMESPACE} into setup.yaml..."
  local setupYaml="${TEMP_DIR}"/setup.yaml

  sed -i "s|{{ .Namespace }}|${CES_NAMESPACE}|g" "${setupYaml}" > /dev/null
}

# Apply the setup resources to the current namespace.
applyResources() {
  echo "Applying resources for setup..."
  local configYaml="${TEMP_DIR}"/config.yaml
  local setupYaml="${TEMP_DIR}"/setup.yaml

  kubectl --namespace "${CES_NAMESPACE}" apply -f "${configYaml}" > /dev/null
  kubectl --namespace "${CES_NAMESPACE}" apply -f "${setupYaml}" > /dev/null
}
createSetupJsonConfigMap() {
  echo "Creating setup.json config map..."
  kubectl --namespace "${CES_NAMESPACE}" create configmap k8s-ces-setup-json --from-file=image/scripts/dev/setup.json
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

TEMP_DIR="$(mktemp -d)"
echo "Created temporary directory: ${TEMP_DIR}"

createSetupJsonConfigMap
downloadLatestSetupReleaseResources
templateNamespace
applyResources

echo "Cleaning up temporary directory..."
rm -rf "${TEMP_DIR}"

echo "**** Finished installLatestK8sCesSetup.sh"
