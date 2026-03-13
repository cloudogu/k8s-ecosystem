#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_NAME="${K3D_CLUSTER_NAME:-k3ces-dev}"
FQDN="${FQDN:-${CES_FQDN:-k3ces.localdomain}}"
HOST_IP="${K3D_HOST_IP:-127.0.0.2}"
API_PORT="${K3D_API_PORT:-6550}"
HTTP_PORT="${K3D_HTTP_PORT:-80}"
HTTPS_PORT="${K3D_HTTPS_PORT:-443}"
SERVER_COUNT="${K3D_SERVER_COUNT:-1}"
AGENT_COUNT="${K3D_AGENT_COUNT:-1}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-${K3D_KUBECONFIG_PATH:-${HOME}/.kube/k3ces.localdomain}}"
K3S_IMAGE="${K3D_K3S_IMAGE:-}"
SKIP_NEXT_STEPS="${K3D_SKIP_NEXT_STEPS:-false}"
MERGE_DEFAULT_KUBECONFIG="${MERGE_DEFAULT_KUBECONFIG:-${K3D_MERGE_DEFAULT_KUBECONFIG:-true}}"
SWITCH_DEFAULT_KUBECONFIG_CONTEXT="${SWITCH_DEFAULT_KUBECONFIG_CONTEXT:-${K3D_SWITCH_DEFAULT_KUBECONFIG_CONTEXT:-false}}"
DEFAULT_KUBECONFIG_PATH="${DEFAULT_KUBECONFIG_PATH:-${K3D_DEFAULT_KUBECONFIG_PATH:-${HOME}/.kube/config}}"
DEFAULT_NAMESPACE="${CES_NAMESPACE:-ecosystem}"
LOCAL_REGISTRY_ENABLED="${LOCAL_REGISTRY_ENABLED:-true}"
LOCAL_REGISTRY_PROXY_NAME="${LOCAL_REGISTRY_PROXY_NAME:-registry-proxy.localhost}"
LOCAL_REGISTRY_PROXY_PORT="${LOCAL_REGISTRY_PROXY_PORT:-5002}"
LOCAL_REGISTRY_CLUSTER_PORT="${LOCAL_REGISTRY_CLUSTER_PORT:-5000}"
LOCAL_REGISTRY_PROXY_CONTAINER="k3d-${LOCAL_REGISTRY_PROXY_NAME}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <create|delete|kubeconfig>

Environment overrides:
  K3D_CLUSTER_NAME       Cluster name (default: ${CLUSTER_NAME})
  FQDN                   CES fqdn for host hint (default: ${FQDN})
  K3D_HOST_IP            Loopback IP for HTTP/HTTPS on the host (default: ${HOST_IP})
  K3D_API_PORT           Kubernetes API port on the host (default: ${API_PORT})
  K3D_HTTP_PORT          HTTP port on the host (default: ${HTTP_PORT})
  K3D_HTTPS_PORT         HTTPS port on the host (default: ${HTTPS_PORT})
  K3D_SERVER_COUNT       Number of k3d server nodes (default: ${SERVER_COUNT})
  K3D_AGENT_COUNT        Number of k3d agent nodes (default: ${AGENT_COUNT})
  KUBECONFIG_PATH        Output path for the kubeconfig (default: ${KUBECONFIG_PATH})
  K3D_K3S_IMAGE          Optional k3s image override
  K3D_SKIP_NEXT_STEPS    Suppress the post-create hint output (default: ${SKIP_NEXT_STEPS})
  CES_NAMESPACE                         Default namespace written into the kubeconfig context (default: ${DEFAULT_NAMESPACE})
  MERGE_DEFAULT_KUBECONFIG             Merge the cluster into the default kubeconfig (default: ${MERGE_DEFAULT_KUBECONFIG})
  SWITCH_DEFAULT_KUBECONFIG_CONTEXT    Switch current context in the default kubeconfig (default: ${SWITCH_DEFAULT_KUBECONFIG_CONTEXT})
  DEFAULT_KUBECONFIG_PATH              Target file for the merged default kubeconfig (default: ${DEFAULT_KUBECONFIG_PATH})
  LOCAL_REGISTRY_ENABLED               Attach the local proxy registry and configure a registry mirror (default: ${LOCAL_REGISTRY_ENABLED})
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
  require_command k3d
  require_command kubectl
  require_command jq
}

local_registry_exists() {
  if [[ "${LOCAL_REGISTRY_ENABLED}" != "true" ]]; then
    return 0
  fi

  k3d registry list "${LOCAL_REGISTRY_PROXY_NAME}" -o json 2>/dev/null | jq -e 'length > 0' >/dev/null 2>&1
}

write_registry_config() {
  local file_path="$1"

  cat > "${file_path}" <<EOF
mirrors:
  "registry.cloudogu.com":
    endpoint:
      - "http://${LOCAL_REGISTRY_PROXY_CONTAINER}:${LOCAL_REGISTRY_CLUSTER_PORT}"
EOF
}

write_kubeconfig() {
  mkdir -p "$(dirname "${KUBECONFIG_PATH}")"
  k3d kubeconfig write "${CLUSTER_NAME}" --output "${KUBECONFIG_PATH}" --overwrite >/dev/null
  chmod 600 "${KUBECONFIG_PATH}"
  local context_name
  context_name="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" config current-context 2>/dev/null || true)"
  set_namespace_for_kubeconfig "${KUBECONFIG_PATH}" "${context_name}"
  merge_default_kubeconfig "${context_name}"
}

set_namespace_for_kubeconfig() {
  local kubeconfig_path="$1"
  local context_name="$2"

  if [[ -z "${DEFAULT_NAMESPACE}" || -z "${context_name}" ]]; then
    return 0
  fi

  KUBECONFIG="${kubeconfig_path}" kubectl config set-context "${context_name}" --namespace "${DEFAULT_NAMESPACE}" >/dev/null
}

merge_default_kubeconfig() {
  local context_name="${1:-}"

  if [[ "${MERGE_DEFAULT_KUBECONFIG}" != "true" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "${DEFAULT_KUBECONFIG_PATH}")"
  k3d kubeconfig merge "${CLUSTER_NAME}" \
    --output "${DEFAULT_KUBECONFIG_PATH}" \
    --kubeconfig-switch-context="${SWITCH_DEFAULT_KUBECONFIG_CONTEXT}" >/dev/null
  set_namespace_for_kubeconfig "${DEFAULT_KUBECONFIG_PATH}" "${context_name}"
}

resolve_kubeconfig_references() {
  local context_name
  context_name="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" config current-context 2>/dev/null || true)"
  if [[ -z "${context_name}" ]]; then
    return 0
  fi

  local cluster_name
  cluster_name="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" config view --raw -o "jsonpath={.contexts[?(@.name==\"${context_name}\")].context.cluster}" 2>/dev/null || true)"
  local user_name
  user_name="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" config view --raw -o "jsonpath={.contexts[?(@.name==\"${context_name}\")].context.user}" 2>/dev/null || true)"

  printf '%s\t%s\t%s\n' "${context_name}" "${cluster_name}" "${user_name}"
}

remove_default_kubeconfig_references() {
  if [[ "${MERGE_DEFAULT_KUBECONFIG}" != "true" ]]; then
    return 0
  fi

  if [[ ! -f "${DEFAULT_KUBECONFIG_PATH}" || ! -f "${KUBECONFIG_PATH}" ]]; then
    return 0
  fi

  local context_name=""
  local cluster_name=""
  local user_name=""
  IFS=$'\t' read -r context_name cluster_name user_name < <(resolve_kubeconfig_references)

  if [[ -z "${context_name}" ]]; then
    return 0
  fi

  local current_context
  current_context="$(KUBECONFIG="${DEFAULT_KUBECONFIG_PATH}" kubectl config current-context 2>/dev/null || true)"
  if [[ "${current_context}" == "${context_name}" ]]; then
    KUBECONFIG="${DEFAULT_KUBECONFIG_PATH}" kubectl config unset current-context >/dev/null 2>&1 || true
  fi

  KUBECONFIG="${DEFAULT_KUBECONFIG_PATH}" kubectl config delete-context "${context_name}" >/dev/null 2>&1 || true
  if [[ -n "${cluster_name}" ]]; then
    KUBECONFIG="${DEFAULT_KUBECONFIG_PATH}" kubectl config delete-cluster "${cluster_name}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${user_name}" ]]; then
    KUBECONFIG="${DEFAULT_KUBECONFIG_PATH}" kubectl config unset "users.${user_name}" >/dev/null 2>&1 || true
  fi
}

print_next_steps() {
  cat <<EOF
Cluster '${CLUSTER_NAME}' is ready.

Kubeconfig:
  dedicated: ${KUBECONFIG_PATH}
  default:   ${DEFAULT_KUBECONFIG_PATH} (merged: ${MERGE_DEFAULT_KUBECONFIG})
  namespace: ${DEFAULT_NAMESPACE}

Hosts entry:
  sudo sh -c 'echo "${HOST_IP} ${FQDN}" >> /etc/hosts'

Configuration:
  cp k3d/config.env.template k3d/config.env
  edit k3d/config.env

Manual bootstrap:
  k3d/install.sh

Managed workflow:
  k3d/ecosystem.sh create <name>
EOF
}

create_cluster() {
  local registry_config_file=""
  trap 'rm -f "${registry_config_file:-}"; trap - RETURN' RETURN

  if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    echo "cluster '${CLUSTER_NAME}' already exists" >&2
    exit 1
  fi

  if [[ "${LOCAL_REGISTRY_ENABLED}" == "true" ]]; then
    if ! local_registry_exists; then
      echo "local proxy registry '${LOCAL_REGISTRY_PROXY_NAME}' is not running" >&2
      echo "start it first with: k3d/registry.sh start" >&2
      exit 1
    fi
    registry_config_file="$(mktemp)"
    write_registry_config "${registry_config_file}"
  fi

  local args=(
    cluster create "${CLUSTER_NAME}"
    --servers "${SERVER_COUNT}"
    --agents "${AGENT_COUNT}"
    --api-port "${HOST_IP}:${API_PORT}"
    -p "${HOST_IP}:${HTTP_PORT}:80@loadbalancer"
    -p "${HOST_IP}:${HTTPS_PORT}:443@loadbalancer"
    --k3s-arg "--disable=traefik@server:0"
    --kubeconfig-update-default=false
    --kubeconfig-switch-context=false
    --wait
  )

  if [[ -n "${K3S_IMAGE}" ]]; then
    args+=(--image "${K3S_IMAGE}")
  fi

  if [[ "${LOCAL_REGISTRY_ENABLED}" == "true" ]]; then
    args+=(
      --registry-use "${LOCAL_REGISTRY_PROXY_CONTAINER}:${LOCAL_REGISTRY_CLUSTER_PORT}"
      --registry-config "${registry_config_file}"
    )
  fi

  k3d "${args[@]}"
  write_kubeconfig
  kubectl --kubeconfig "${KUBECONFIG_PATH}" get nodes
  if [[ "${SKIP_NEXT_STEPS}" != "true" ]]; then
    print_next_steps
  fi
}

delete_cluster() {
  if ! k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    echo "cluster '${CLUSTER_NAME}' does not exist" >&2
    exit 1
  fi

  remove_default_kubeconfig_references
  k3d cluster delete "${CLUSTER_NAME}"
  rm -f "${KUBECONFIG_PATH}"
}

main() {
  ensure_prerequisites

  case "${1:-}" in
    create)
      create_cluster
      ;;
    delete)
      delete_cluster
      ;;
    kubeconfig)
      write_kubeconfig
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
