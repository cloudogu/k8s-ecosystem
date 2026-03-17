#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GLOBAL_ENV_FILE="${K3D_GLOBAL_ENV_FILE:-${SCRIPT_DIR}/config.env}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [INSTANCE_ENV_FILE]

Bootstraps CES on the current k3d cluster by reusing image/scripts/dev/installEcosystem.sh.

Defaults:
  shared config: ${GLOBAL_ENV_FILE}

Preparation:
  cp k3d/config.env.template k3d/config.env
  edit k3d/config.env
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "missing required command: ${cmd}" >&2
    exit 1
  fi
}

ensure_prerequisites() {
  require_command kubectl
  require_command helm
  require_command curl
  require_command jq
  require_command yq
}

load_env_file() {
  local env_file="$1"
  local description="$2"

  if [[ ! -f "${env_file}" ]]; then
    echo "${description} file not found: ${env_file}" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${env_file}"
}

set_defaults() {
  local remote_image_registry_url="https://registry.cloudogu.com"
  local remote_helm_registry_host="registry.cloudogu.com"

  DOGU_REGISTRY_URL="${DOGU_REGISTRY_URL:-https://dogu.cloudogu.com/api/v2/dogus}"
  DOGU_REGISTRY_URLSCHEMA="${DOGU_REGISTRY_URLSCHEMA:-default}"
  IMAGE_REGISTRY_URL="${IMAGE_REGISTRY_URL:-${remote_image_registry_url}}"
  HELM_REGISTRY_HOST="${HELM_REGISTRY_HOST:-${remote_helm_registry_host}}"
  RUNTIME_HELM_REGISTRY_HOST="${RUNTIME_HELM_REGISTRY_HOST:-${HELM_REGISTRY_HOST}}"
  HELM_REGISTRY_SCHEMA="${HELM_REGISTRY_SCHEMA:-oci}"
  HELM_REGISTRY_PLAIN_HTTP="${HELM_REGISTRY_PLAIN_HTTP:-false}"
  LOCAL_REGISTRY_ENABLED="${LOCAL_REGISTRY_ENABLED:-true}"
  LOCAL_REGISTRY_PROXY_NAME="${LOCAL_REGISTRY_PROXY_NAME:-registry-proxy.localhost}"
  LOCAL_REGISTRY_PROXY_PORT="${LOCAL_REGISTRY_PROXY_PORT:-5002}"
  LOCAL_REGISTRY_CLUSTER_PORT="${LOCAL_REGISTRY_CLUSTER_PORT:-5000}"
  CES_NAMESPACE="${CES_NAMESPACE:-ecosystem}"
  HELM_REPOSITORY_NAMESPACE="${HELM_REPOSITORY_NAMESPACE:-k8s}"
  FQDN="${FQDN:-k3ces.localdomain}"
  KUBE_CTX_NAME="${KUBE_CTX_NAME:-${FQDN}}"
  KUBECONFIG_PATH="${KUBECONFIG_PATH:-${HOME}/.kube/${KUBE_CTX_NAME}}"
  FORCE_UPGRADE_ECOSYSTEM="${FORCE_UPGRADE_ECOSYSTEM:-false}"
  INSTALL_LONGHORN="false"

  if [[ "${LOCAL_REGISTRY_ENABLED}" == "true" ]]; then
    local local_proxy_host="localhost:${LOCAL_REGISTRY_PROXY_PORT}"
    local local_proxy_runtime_host="k3d-${LOCAL_REGISTRY_PROXY_NAME}:${LOCAL_REGISTRY_CLUSTER_PORT}"

    if [[ "${HELM_REGISTRY_HOST}" == "${remote_helm_registry_host}" ]]; then
      HELM_REGISTRY_HOST="${local_proxy_host}"
    fi
    if [[ "${RUNTIME_HELM_REGISTRY_HOST}" == "${remote_helm_registry_host}" ]]; then
      RUNTIME_HELM_REGISTRY_HOST="${local_proxy_runtime_host}"
    fi
    HELM_REGISTRY_PLAIN_HTTP="true"
  fi
}

validate_required_vars() {
  local required_vars=(
    DOGU_REGISTRY_USERNAME
    DOGU_REGISTRY_PASSWORD
  )

  if [[ "${LOCAL_REGISTRY_ENABLED}" != "true" ]]; then
    required_vars+=(
      IMAGE_REGISTRY_USERNAME
      IMAGE_REGISTRY_PASSWORD
      HELM_REGISTRY_USERNAME
      HELM_REGISTRY_PASSWORD
    )
  fi

  local missing=0
  local var_name
  for var_name in "${required_vars[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
      echo "missing required setting: ${var_name}" >&2
      missing=1
    fi
  done

  if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
    echo "kubeconfig not found: ${KUBECONFIG_PATH}" >&2
    missing=1
  fi

  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

run_install() {
  cd "${REPO_ROOT}"

  INSTALL_LONGHORN="${INSTALL_LONGHORN}" \
  KUBECONFIG_PATH="${KUBECONFIG_PATH}" \
  image/scripts/dev/installEcosystem.sh \
    "${CES_NAMESPACE}" \
    "${HELM_REPOSITORY_NAMESPACE}" \
    "${DOGU_REGISTRY_USERNAME}" \
    "${DOGU_REGISTRY_PASSWORD}" \
    "${DOGU_REGISTRY_URL}" \
    "${DOGU_REGISTRY_URLSCHEMA}" \
    "${IMAGE_REGISTRY_USERNAME}" \
    "${IMAGE_REGISTRY_PASSWORD}" \
    "${IMAGE_REGISTRY_URL}" \
    "${HELM_REGISTRY_USERNAME}" \
    "${HELM_REGISTRY_PASSWORD}" \
    "${HELM_REGISTRY_HOST}" \
    "${RUNTIME_HELM_REGISTRY_HOST}" \
    "${HELM_REGISTRY_SCHEMA}" \
    "${HELM_REGISTRY_PLAIN_HTTP}" \
    "${KUBE_CTX_NAME}" \
    "1" \
    "${FQDN}" \
    "${FORCE_UPGRADE_ECOSYSTEM}"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  local instance_env_file="${1:-}"

  ensure_prerequisites
  load_env_file "${GLOBAL_ENV_FILE}" "shared config"
  if [[ -n "${instance_env_file}" && "${instance_env_file}" != "${GLOBAL_ENV_FILE}" ]]; then
    load_env_file "${instance_env_file}" "instance config"
  fi
  set_defaults
  validate_required_vars
  run_install
}

main "$@"
