#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_ENV_FILE="${K3D_GLOBAL_ENV_FILE:-${SCRIPT_DIR}/config.env}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <start|stop|delete|status>

Commands:
  start    Create or start the local dev and proxy registries
  stop     Stop both local registries
  delete   Delete both local registries
  status   Show the configured local registry endpoints
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
  require_command docker
  require_command jq
  require_command k3d
}

decode_if_b64() {
  local input="$1"
  if [[ -z "${input}" ]]; then
    return 0
  fi

  if printf '%s' "${input}" | base64 -d >/dev/null 2>&1; then
    printf '%s' "${input}" | base64 -d
  else
    printf '%s' "${input}"
  fi
}

load_global_config() {
  if [[ ! -f "${GLOBAL_ENV_FILE}" ]]; then
    echo "shared config file not found: ${GLOBAL_ENV_FILE}" >&2
    echo "create it from k3d/config.env.template first" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${GLOBAL_ENV_FILE}"

  LOCAL_REGISTRY_ENABLED="${LOCAL_REGISTRY_ENABLED:-true}"
  MANAGE_HOSTS_FILE="${MANAGE_HOSTS_FILE:-true}"
  LOCAL_REGISTRY_STORAGE_PATH="${LOCAL_REGISTRY_STORAGE_PATH:-${HOME}/.local/share/k3d/registries/cloudogu}"
  LOCAL_REGISTRY_DEV_NAME="${LOCAL_REGISTRY_DEV_NAME:-registry-dev.localhost}"
  LOCAL_REGISTRY_DEV_PORT="${LOCAL_REGISTRY_DEV_PORT:-5001}"
  LOCAL_REGISTRY_PROXY_NAME="${LOCAL_REGISTRY_PROXY_NAME:-registry-proxy.localhost}"
  LOCAL_REGISTRY_PROXY_PORT="${LOCAL_REGISTRY_PROXY_PORT:-5002}"
  LOCAL_REGISTRY_CLUSTER_PORT="${LOCAL_REGISTRY_CLUSTER_PORT:-5000}"
  LOCAL_REGISTRY_PROXY_REMOTE_URL="${LOCAL_REGISTRY_PROXY_REMOTE_URL:-https://registry.cloudogu.com}"
  LOCAL_REGISTRY_PROXY_USERNAME="${LOCAL_REGISTRY_PROXY_USERNAME:-${HELM_REGISTRY_USERNAME:-${IMAGE_REGISTRY_USERNAME:-}}}"
  LOCAL_REGISTRY_PROXY_PASSWORD="${LOCAL_REGISTRY_PROXY_PASSWORD:-${HELM_REGISTRY_PASSWORD:-${IMAGE_REGISTRY_PASSWORD:-}}}"
  LOCAL_REGISTRY_PROXY_PASSWORD_DECODED="$(decode_if_b64 "${LOCAL_REGISTRY_PROXY_PASSWORD}")"

  DEV_REGISTRY_CONTAINER_NAME="k3d-${LOCAL_REGISTRY_DEV_NAME}"
  PROXY_REGISTRY_CONTAINER_NAME="k3d-${LOCAL_REGISTRY_PROXY_NAME}"
  DEV_REGISTRY_HOST_ENDPOINT="localhost:${LOCAL_REGISTRY_DEV_PORT}"
  DEV_REGISTRY_CLUSTER_ENDPOINT="${DEV_REGISTRY_CONTAINER_NAME}:${LOCAL_REGISTRY_CLUSTER_PORT}"
  PROXY_REGISTRY_HOST_ENDPOINT="localhost:${LOCAL_REGISTRY_PROXY_PORT}"
  PROXY_REGISTRY_CLUSTER_ENDPOINT="${PROXY_REGISTRY_CONTAINER_NAME}:${LOCAL_REGISTRY_CLUSTER_PORT}"
}

ensure_registry_feature_enabled() {
  if [[ "${LOCAL_REGISTRY_ENABLED}" != "true" ]]; then
    echo "local registries are disabled in ${GLOBAL_ENV_FILE} (LOCAL_REGISTRY_ENABLED=${LOCAL_REGISTRY_ENABLED})" >&2
    exit 1
  fi
}

registry_exists() {
  local name="$1"
  k3d registry list "${name}" -o json 2>/dev/null | jq -e 'length > 0' >/dev/null 2>&1
}

registry_status() {
  local container_name="$1"
  docker inspect --format '{{.State.Status}}' "${container_name}" 2>/dev/null || true
}

build_hosts_file_without_entry() {
  local marker="$1"
  local temp_file="$2"

  if [[ -f /etc/hosts ]]; then
    awk -v marker="${marker}" '
      index($0, marker) == 0 { print }
    ' /etc/hosts > "${temp_file}"
  else
    : > "${temp_file}"
  fi
}

write_hosts_file() {
  local temp_file="$1"

  if [[ "${EUID}" -eq 0 ]]; then
    install -m 644 "${temp_file}" /etc/hosts
  elif command -v sudo >/dev/null 2>&1; then
    sudo install -m 644 "${temp_file}" /etc/hosts
  else
    return 1
  fi
}

ensure_hosts_entries() {
  if [[ "${MANAGE_HOSTS_FILE}" != "true" ]]; then
    return 0
  fi

  local temp_file
  temp_file="$(mktemp)"
  local marker="# k3d-registry-stack"

  build_hosts_file_without_entry "${marker}" "${temp_file}"
  printf '127.0.0.1 %s %s %s %s %s\n' \
    "${LOCAL_REGISTRY_DEV_NAME}" \
    "${DEV_REGISTRY_CONTAINER_NAME}" \
    "${LOCAL_REGISTRY_PROXY_NAME}" \
    "${PROXY_REGISTRY_CONTAINER_NAME}" \
    "${marker}" >> "${temp_file}"

  if ! write_hosts_file "${temp_file}"; then
    rm -f "${temp_file}"
    echo "warning: failed to update /etc/hosts for local registry endpoints" >&2
    echo "manual command: sudo sh -c 'echo \"127.0.0.1 ${LOCAL_REGISTRY_DEV_NAME} ${DEV_REGISTRY_CONTAINER_NAME} ${LOCAL_REGISTRY_PROXY_NAME} ${PROXY_REGISTRY_CONTAINER_NAME} ${marker}\" >> /etc/hosts'" >&2
    return 0
  fi

  rm -f "${temp_file}"
}

remove_hosts_entries() {
  if [[ "${MANAGE_HOSTS_FILE}" != "true" ]]; then
    return 0
  fi

  local temp_file
  temp_file="$(mktemp)"
  local marker="# k3d-registry-stack"

  build_hosts_file_without_entry "${marker}" "${temp_file}"

  if ! write_hosts_file "${temp_file}"; then
    rm -f "${temp_file}"
    echo "warning: failed to clean up /etc/hosts entries for local registry endpoints" >&2
    return 0
  fi

  rm -f "${temp_file}"
}

create_registry() {
  local name="$1"
  local port="$2"
  shift 2

  mkdir -p "${LOCAL_REGISTRY_STORAGE_PATH}"

  k3d registry create "${name}" \
    --port "127.0.0.1:${port}" \
    --volume "${LOCAL_REGISTRY_STORAGE_PATH}:/var/lib/registry" \
    --no-help \
    "$@"
}

ensure_registry_started() {
  local name="$1"
  local port="$2"
  local container_name="$3"
  shift 3

  if registry_exists "${name}"; then
    local status
    status="$(registry_status "${container_name}")"
    if [[ "${status}" != "running" ]]; then
      docker start "${container_name}" >/dev/null
    fi
    return 0
  fi

  create_registry "${name}" "${port}" "$@"
}

start_stack() {
  ensure_registry_started "${LOCAL_REGISTRY_DEV_NAME}" "${LOCAL_REGISTRY_DEV_PORT}" "${DEV_REGISTRY_CONTAINER_NAME}"

  local proxy_args=(
    --proxy-remote-url "${LOCAL_REGISTRY_PROXY_REMOTE_URL}"
  )
  if [[ -n "${LOCAL_REGISTRY_PROXY_USERNAME}" ]]; then
    proxy_args+=(--proxy-username "${LOCAL_REGISTRY_PROXY_USERNAME}")
  fi
  if [[ -n "${LOCAL_REGISTRY_PROXY_PASSWORD_DECODED}" ]]; then
    proxy_args+=(--proxy-password "${LOCAL_REGISTRY_PROXY_PASSWORD_DECODED}")
  fi

  ensure_registry_started "${LOCAL_REGISTRY_PROXY_NAME}" "${LOCAL_REGISTRY_PROXY_PORT}" "${PROXY_REGISTRY_CONTAINER_NAME}" "${proxy_args[@]}"
  ensure_hosts_entries
  print_status
}

stop_registry_if_running() {
  local container_name="$1"

  if [[ "$(registry_status "${container_name}")" == "running" ]]; then
    docker stop "${container_name}" >/dev/null
  fi
}

stop_stack() {
  stop_registry_if_running "${PROXY_REGISTRY_CONTAINER_NAME}"
  stop_registry_if_running "${DEV_REGISTRY_CONTAINER_NAME}"
}

delete_registry_if_present() {
  local name="$1"

  if registry_exists "${name}"; then
    k3d registry delete "${name}" >/dev/null
  fi
}

delete_stack() {
  delete_registry_if_present "${LOCAL_REGISTRY_PROXY_NAME}"
  delete_registry_if_present "${LOCAL_REGISTRY_DEV_NAME}"
  remove_hosts_entries
}

print_registry_row() {
  local type="$1"
  local name="$2"
  local container_name="$3"
  local host_endpoint="$4"
  local cluster_endpoint="$5"

  local status="absent"
  if registry_exists "${name}"; then
    status="$(registry_status "${container_name}")"
    if [[ -z "${status}" ]]; then
      status="created"
    fi
  fi

  printf '%-8s %-30s %-10s %-22s %s\n' \
    "${type}" \
    "${name}" \
    "${status}" \
    "${host_endpoint}" \
    "${cluster_endpoint}"
}

print_status() {
  cat <<EOF
Local registry stack

Shared storage:
  ${LOCAL_REGISTRY_STORAGE_PATH}

Registry rows:
EOF

  printf '%-8s %-30s %-10s %-22s %s\n' "TYPE" "NAME" "STATUS" "HOST" "CLUSTER"
  print_registry_row "dev" "${LOCAL_REGISTRY_DEV_NAME}" "${DEV_REGISTRY_CONTAINER_NAME}" "${DEV_REGISTRY_HOST_ENDPOINT}" "${DEV_REGISTRY_CLUSTER_ENDPOINT}"
  print_registry_row "proxy" "${LOCAL_REGISTRY_PROXY_NAME}" "${PROXY_REGISTRY_CONTAINER_NAME}" "${PROXY_REGISTRY_HOST_ENDPOINT}" "${PROXY_REGISTRY_CLUSTER_ENDPOINT}"

  cat <<EOF

Recommended endpoints:
  Push local images/charts: ${DEV_REGISTRY_HOST_ENDPOINT}
  Configure CES consumers:  ${PROXY_REGISTRY_CLUSTER_ENDPOINT}
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  ensure_prerequisites
  load_global_config

  local command="${1:-}"
  case "${command}" in
    start)
      ensure_registry_feature_enabled
      start_stack
      ;;
    stop)
      ensure_registry_feature_enabled
      stop_stack
      ;;
    delete)
      ensure_registry_feature_enabled
      delete_stack
      ;;
    status)
      print_status
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
