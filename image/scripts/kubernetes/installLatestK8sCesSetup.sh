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

  echo ""
  cat "${TEMP_DIR}"/config.yaml
  cat "${TEMP_DIR}"/setup.yaml
  echo ""
}

# Replace the namespace placeholder with the actual namespace of the cluster.
templateNamespace() {
  echo "Templating namespace ${CES_NAMESPACE} into setup.yaml..."
  local setupYaml="${TEMP_DIR}"/setup.yaml

  sed -i "s|{{ .Namespace }}|${CES_NAMESPACE}|g" "${setupYaml}"
}

# Apply the setup resources to the current namespace.
applyResources() {
  echo "Applying resources for setup..."
  local configYaml="${TEMP_DIR}"/config.yaml
  local setupYaml="${TEMP_DIR}"/setup.yaml

  kubectl --namespace "${CES_NAMESPACE}" apply -f "${configYaml}"
  kubectl --namespace "${CES_NAMESPACE}" apply -f "${setupYaml}"
}
createSetupJsonConfigMap() {
  echo "Creating setup.json config map..."
  kubectl --namespace "${CES_NAMESPACE}" create configmap k8s-ces-setup-json --from-file=/vagrant/image/setup.json
}

echo "**** Executing installLatestK8sCesSetup.sh..."

TEMP_DIR="$(mktemp -d)"
echo "Created temporary directory: ${TEMP_DIR}"

createSetupJsonConfigMap
downloadLatestSetupReleaseResources
templateNamespace
applyResources

echo "Cleaning up temporary directory..."
rm -rf "${TEMP_DIR}"

echo "**** Finished installLatestK8sCesSetup.sh"
