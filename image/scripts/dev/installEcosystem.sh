#!/bin/bash
# This file is responsible to install or update the ces in the cluster.
set -o errexit
set -o nounset
set -o pipefail

# load blueprint helpers
. "image/scripts/dev/blueprintHandling.sh"

# load component helpers
. "image/scripts/dev/componentHandling.sh"

# load internal FQDN helpers
. "image/scripts/dev/internalFqdnHandling.sh"

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
component_helm_registry_host="${helm_registry_host}"

# Backward-compatible argument parsing:
# legacy callers pass 18 args, new callers pass 19 args with an explicit component registry host.
if [[ $# -ge 19 ]]; then
  component_helm_registry_host=${13}
  helm_registry_schema=${14}
  helm_registry_plain_http=${15}
  kube_ctx_name=${16}
  default_class_replica_count="${17:-2}"
  fqdn=${18}
  forceUpgradeEcosystem=${19}
else
  helm_registry_schema=${13}
  helm_registry_plain_http=${14}
  kube_ctx_name=${15}
  default_class_replica_count="${16:-2}"
  fqdn=${17}
  forceUpgradeEcosystem=${18}
fi
INSTALL_LONGHORN="${INSTALL_LONGHORN:-true}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-${HOME}/.kube/$kube_ctx_name}"
ENABLE_INTERNAL_FQDN_DNS="${ENABLE_INTERNAL_FQDN_DNS:-false}"

registry_chart_ref() {
  local chart_name="$1"
  printf '%s://%s/%s/%s' "${helm_registry_schema}" "${helm_registry_host}" "${helm_repository_namespace}" "${chart_name}"
}

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

  local helm_registry_args=()
  if [[ "${helm_registry_plain_http}" == "true" ]]; then
    helm_registry_args+=(--plain-http)
  fi
  if [[ "${helm_registry_insecure_tls:-false}" == "true" ]]; then
    helm_registry_args+=(--insecure-skip-tls-verify)
  fi

  login_registry_helm "${helm_registry_host}" "${helm_registry_username}" "${helm_registry_password}" "${helm_registry_plain_http}"

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
    "${component_helm_registry_host}" \
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

  if [ "${INSTALL_LONGHORN}" = "true" ]; then
    echo "Installing Longhorn..."
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
  else
    echo "Skipping Longhorn installation (INSTALL_LONGHORN=${INSTALL_LONGHORN})."
  fi

  # Install SnapshotController
  helm upgrade -i k8s-snapshot-controller-crd "$(registry_chart_ref "k8s-snapshot-controller-crd")" \
    "${helm_registry_args[@]}" \
    --namespace="kube-system" --version 8.2.1-3

  helm upgrade -i k8s-snapshot-controller "$(registry_chart_ref "k8s-snapshot-controller")" \
    "${helm_registry_args[@]}" \
    --namespace="kube-system" --version 8.2.1-3

  # Install Component CRD
  helm upgrade -i k8s-component-operator-crd "$(registry_chart_ref "k8s-component-operator-crd")" \
    "${helm_registry_args[@]}" \
    --namespace="${CES_NAMESPACE}"

  # Install Blueprint CRD
  helm upgrade -i k8s-blueprint-operator-crd "$(registry_chart_ref "k8s-blueprint-operator-crd")" \
    "${helm_registry_args[@]}" \
    --namespace="${CES_NAMESPACE}"

  # Install ecosystem-core
  ADDITIONAL_VALUES_TEMPLATE=image/scripts/dev/additionalValues.yaml.tpl
  ADDITIONAL_VALUES_YAML=image/scripts/dev/.additionalValues.yaml
  cp ${ADDITIONAL_VALUES_TEMPLATE} ${ADDITIONAL_VALUES_YAML}
  helm upgrade -i ecosystem-core "$(registry_chart_ref "ecosystem-core")" \
    "${helm_registry_args[@]}" \
    --values ${ADDITIONAL_VALUES_YAML} \
    --namespace="${CES_NAMESPACE}" \
    --timeout=20m

  ensure_internal_fqdn_dns

  wait_for_component_healthy "k8s-dogu-operator" "${CES_NAMESPACE}" 900

  # Apply blueprint with latest dogu versions
  patch_and_apply_blueprint_with_latest_versions "${dogu_registry_username}" "${dogu_registry_password}" "${fqdn}"

  # wait until blueprint is completed, then stop the blueprint
  wait_and_stop_blueprint "blueprint" "${CES_NAMESPACE}" 900
}

# --- Main ---

# set environment for helm and kubectl
export KUBECONFIG="${KUBECONFIG_PATH}"

ensure_namespace

echo "set default k8s namespace"
kubectl config set-context --current --namespace "${CES_NAMESPACE}"

if shouldApplyResources; then
  echo "**** Executing installEcosystem.sh..."
  applyResources
  echo "**** Finished installEcosystem.sh"
else
  ensure_internal_fqdn_dns_if_service_exists
  echo "**** ecosystem is already installed; not applying resources"
fi
