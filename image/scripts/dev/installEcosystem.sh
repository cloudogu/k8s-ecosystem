#!/bin/bash
# This file is responsible to install or update the ces in the cluster.
set -o errexit
set -o nounset
set -o pipefail

# load blueprint helpers
. "image/scripts/dev/blueprintHandling.sh"

# load component helpers
. "image/scripts/dev/componentHandling.sh"

# load configMap / secret helpers
. "image/scripts/dev/configHandling.sh"

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
fqdn=${17}
forceUpgradeEcosystem=${18}

# shouldApplyResources checks whether ecosystem-core is already installed and if an upgrade should be applied
shouldApplyResources() {
  # Return true if forced via flag
  if [ "${forceUpgradeEcosystem}" = "true" ]; then
    return 0
  fi

  # Check if helm release ecosystem-core exists in the target namespace
  if helm status ecosystem-core --namespace "${CES_NAMESPACE}" >/dev/null 2>&1; then
    # Release exists -> do not apply
    return 1
  else
    # Release not found -> apply
    return 0
  fi
}

# Apply the setup resources to the current namespace.
applyResources() {
  echo "Applying resources for setup..."

  # Remove hard coded registry.cloudogu.com if helm 3.13 is released. Use then --plain-http flag with the proxy registry.
  login_registry_helm "registry.cloudogu.com" "${helm_registry_username}" "${helm_registry_password}"

  # Ensure Registries
  ensure_dogu_registry_secret \
    "${dogu_registry_url}" \
    "${dogu_registry_urlschema}" \
    "${dogu_registry_username}" \
    "${dogu_registry_password}" \
    "${CES_NAMESPACE}"

  ensure_container_registry_secret \
    "${image_registry_url}" \
    "${image_registry_username}" \
    "${image_registry_password}" \
    "${CES_NAMESPACE}"

  ensure_helm_registry_config \
    "${helm_registry_host}" \
    "${helm_registry_schema}" \
    "${helm_registry_plain_http}" \
    "${helm_registry_insecure_tls:-false}" \
    "${helm_registry_username}" \
    "${helm_registry_password}" \
    "${CES_NAMESPACE}"

  ensure_initial_admin_password_secret \
    "${CES_NAMESPACE}"

  ensure_certificate_secret \
    "${CES_NAMESPACE}"

  # Install Longhorn
  helm repo add longhorn https://charts.longhorn.io
  helm repo update

  LONGHORN_VALUES_TEMPLATE=image/scripts/dev/longhorn-values.yaml.tpl
  LONGHORN_VALUES_YAML=image/scripts/dev/.longhorn-values.yaml
  cp ${LONGHORN_VALUES_TEMPLATE} ${LONGHORN_VALUES_YAML}
  sed --in-place "s|DEFAULTCLASSREPLICACOUNT|${default_class_replica_count}|g" ${LONGHORN_VALUES_YAML}

  helm upgrade -i longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --create-namespace \
    --values ${LONGHORN_VALUES_YAML} \
    --version 1.10.0

  # Install SnapshotController
  helm upgrade -i k8s-snapshot-controller-crd "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-snapshot-controller-crd" \
    --namespace="kube-system" --version 8.2.1-3

  helm upgrade -i k8s-snapshot-controller "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-snapshot-controller" \
    --namespace="kube-system" --version 8.2.1-3

  # Install Component CRD
  helm upgrade -i k8s-component-operator-crd "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-component-operator-crd" \
    --namespace="${CES_NAMESPACE}"

  # Install Blueprint CRD
  helm upgrade -i k8s-blueprint-operator-crd "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-blueprint-operator-crd" \
    --namespace="${CES_NAMESPACE}"

  # Install ecosystem-core
  ADDITIONAL_VALUES_TEMPLATE=image/scripts/dev/additionalValues.yaml.tpl
  ADDITIONAL_VALUES_YAML=image/scripts/dev/.additionalValues.yaml
  cp ${ADDITIONAL_VALUES_TEMPLATE} ${ADDITIONAL_VALUES_YAML}
  helm upgrade -i ecosystem-core "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/ecosystem-core" \
    --values ${ADDITIONAL_VALUES_YAML} \
    --namespace="${CES_NAMESPACE}" \
    --timeout=20m

  wait_for_component_healthy "k8s-dogu-operator" "ecosystem" 900

  # Apply blueprint with latest dogu versions
  patch_and_apply_blueprint_with_latest_versions "${dogu_registry_username}" "${dogu_registry_password}" "${fqdn}"

  # wait until blueprint is completed, then stop the blueprint
  wait_and_stop_blueprint "blueprint" "${CES_NAMESPACE}" 900
}

# --- Main ---

# set environment for helm and kubectl
export KUBECONFIG="${HOME}/.kube/$kube_ctx_name"

echo "set default k8s namespace"
kubectl config set-context --current --namespace "${CES_NAMESPACE}"

if shouldApplyResources; then
  echo "**** Executing installEcosystem.sh..."
  applyResources
  echo "**** Finished installEcosystem.sh"
else
  echo "**** ecosystem is already installed; not applying resources"
fi