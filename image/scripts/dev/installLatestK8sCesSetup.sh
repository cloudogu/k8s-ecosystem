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
dogu_registry_urlschema=${6}
image_registry_username=${7}
image_registry_password=${8}
image_registry_url=${9}
helm_registry_username=${10}
helm_registry_password=${11}
helm_registry_host=${12}
helm_registry_schema=${13}
helm_registry_plain_http=${14}
kube_ctx_name=${15}
default_class_replica_count="${16:-2}"

ADDITIONAL_VALUES_TEMPLATE=image/scripts/dev/additionalValues.yaml.tpl
ADDITIONAL_VALUES_YAML=additionalValues.yaml

# set environment for helm and kubectl
export KUBECONFIG="${HOME}/.kube/$kube_ctx_name"

echo "set default k8s namespace"
kubectl config set-context --current --namespace "${CES_NAMESPACE}"

# Apply the setup resources to the current namespace.
applyResources() {
  echo "Applying resources for setup..."
  # Remove hard coded registry.cloudogu.com if helm 3.13 is released. Use then --plain-http flag with the proxy registry.
  base64 --decode <<< "${helm_registry_password}" | helm registry login registry.cloudogu.com --username "${helm_registry_username}" --password-stdin

  # Use generated .setup.json if it exists, otherwise use setup.json
  SETUP_JSON=image/scripts/dev/setup.json
  if [ -f image/scripts/dev/.setup.json ]; then
    SETUP_JSON=image/scripts/dev/.setup.json
  fi

  # Replace values in yaml template
  cp ${ADDITIONAL_VALUES_TEMPLATE} ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|CONTAINER_REGISTRY_SECRET_URL|${image_registry_url}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|CONTAINER_REGISTRY_SECRET_USERNAME|${image_registry_username}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|CONTAINER_REGISTRY_SECRET_PASSWORD|${image_registry_password}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|DOGU_REGISTRY_SECRET_URL|${dogu_registry_url}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|DOGU_REGISTRY_SECRET_URL_SCHEMA|${dogu_registry_urlschema}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|DOGU_REGISTRY_SECRET_USERNAME|${dogu_registry_username}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|DOGU_REGISTRY_SECRET_PASSWORD|${dogu_registry_password}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|HELM_REGISTRY_SECRET_HOST|${helm_registry_host}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|HELM_REGISTRY_SECRET_SCHEMA|${helm_registry_schema}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|HELM_REGISTRY_SECRET_PLAIN_HTTP|${helm_registry_plain_http}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|HELM_REGISTRY_SECRET_USERNAME|${helm_registry_username}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|HELM_REGISTRY_SECRET_PASSWORD|${helm_registry_password}|g" ${ADDITIONAL_VALUES_YAML}
  sed --in-place "s|DEFAULTCLASSREPLICACOUNT|${default_class_replica_count}|g" ${ADDITIONAL_VALUES_YAML}

  # Install k8s-ces-setup via Helm
  helm upgrade -i k8s-ces-setup "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-ces-setup" \
    --values ${ADDITIONAL_VALUES_YAML} \
    --namespace="${CES_NAMESPACE}" \
    --set-file=setup_json=${SETUP_JSON}
}


checkIfSetupIsInstalled() {
    echo "Check if setup is already installed or executed"
    if kubectl -n "${CES_NAMESPACE}" get deployments k8s-ces-setup > /dev/null
    then
      echo "Setup is already installed: Found k8s-ces-setup deployment"
      exit 0
    fi

    if kubectl -n "${CES_NAMESPACE}" get deployments k8s-dogu-operator-controller-manager > /dev/null
    then
      echo "Setup is already executed: Found k8s-dogu-operator deployment"
      exit 0
    fi
}

echo "**** Executing installLatestK8sCesSetup.sh..."

checkIfSetupIsInstalled
applyResources

echo "**** Finished installLatestK8sCesSetup.sh"
