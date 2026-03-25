#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_SCRIPT="${SCRIPT_DIR}/cluster.sh"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"
REGISTRY_SCRIPT="${SCRIPT_DIR}/registry.sh"
GLOBAL_ENV_FILE="${K3D_GLOBAL_ENV_FILE:-${SCRIPT_DIR}/config.env}"
ENV_DIR="${SCRIPT_DIR}/environments"

mkdir -p "${ENV_DIR}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <create|open|start|stop|delete|list> [NAME]

Commands:
  create NAME   Create a new k3d cluster and install CES into it
  open NAME     Open the ecosystem URL in the default browser
  start NAME    Start an existing k3d cluster
  stop NAME     Stop an existing k3d cluster
  delete NAME   Delete an existing k3d cluster
  list          List local k3d ecosystems
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
  require_command jq
}

load_global_config_if_present() {
  if [[ -f "${GLOBAL_ENV_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${GLOBAL_ENV_FILE}"
  fi

  BASE_DOMAIN="${BASE_DOMAIN:-k3ces.localdomain}"
  KUBECONFIG_DIRECTORY="${KUBECONFIG_DIRECTORY:-${HOME}/.kube}"
  MANAGE_HOSTS_FILE="${MANAGE_HOSTS_FILE:-${K3D_MANAGE_HOSTS_FILE:-true}}"
  MERGE_DEFAULT_KUBECONFIG="${MERGE_DEFAULT_KUBECONFIG:-${K3D_MERGE_DEFAULT_KUBECONFIG:-true}}"
  SWITCH_DEFAULT_KUBECONFIG_CONTEXT="${SWITCH_DEFAULT_KUBECONFIG_CONTEXT:-${K3D_SWITCH_DEFAULT_KUBECONFIG_CONTEXT:-false}}"
  DEFAULT_KUBECONFIG_PATH="${DEFAULT_KUBECONFIG_PATH:-${K3D_DEFAULT_KUBECONFIG_PATH:-${HOME}/.kube/config}}"
  LOCAL_REGISTRY_ENABLED="${LOCAL_REGISTRY_ENABLED:-true}"
  LOCAL_REGISTRY_DEV_PORT="${LOCAL_REGISTRY_DEV_PORT:-5001}"
  LOCAL_REGISTRY_PROXY_NAME="${LOCAL_REGISTRY_PROXY_NAME:-registry-proxy.localhost}"
  LOCAL_REGISTRY_CLUSTER_PORT="${LOCAL_REGISTRY_CLUSTER_PORT:-5000}"
}

load_global_config() {
  if [[ ! -f "${GLOBAL_ENV_FILE}" ]]; then
    echo "shared config file not found: ${GLOBAL_ENV_FILE}" >&2
    echo "create it from k3d/config.env.template first" >&2
    exit 1
  fi

  load_global_config_if_present
}

validate_name() {
  local name="$1"
  if [[ ! "${name}" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "invalid ecosystem name '${name}': use lowercase letters, numbers and dashes only" >&2
    exit 1
  fi
}

instance_env_file() {
  local name="$1"
  printf '%s/%s.env' "${ENV_DIR}" "${name}"
}

instance_coredns_manifest_file() {
  local name="$1"
  printf '%s/%s.coredns-custom.yaml' "${ENV_DIR}" "${name}"
}

get_env_value() {
  local env_file="$1"
  local var_name="$2"
  (
    # shellcheck disable=SC1090
    source "${env_file}"
    eval "printf '%s' \"\${${var_name}:-}\""
  )
}

cluster_exists() {
  local name="$1"
  k3d cluster list "${name}" >/dev/null 2>&1
}

run_with_instance_env() {
  local env_file="$1"
  shift

  (
    set -a
    if [[ -f "${GLOBAL_ENV_FILE}" ]]; then
      # shellcheck disable=SC1090
      source "${GLOBAL_ENV_FILE}"
    fi
    # shellcheck disable=SC1090
    source "${env_file}"
    set +a
    "$@"
  )
}

print_ecosystem_summary() {
  local name="$1"
  local fqdn="$2"
  local kubeconfig_path="$3"

  cat <<EOF
Ecosystem '${name}' is ready.

URL:
  https://${fqdn}

Dedicated kubeconfig:
  ${kubeconfig_path}

Default kubeconfig:
  ${DEFAULT_KUBECONFIG_PATH} (merged: ${MERGE_DEFAULT_KUBECONFIG})

Hosts file:
  managed automatically: ${MANAGE_HOSTS_FILE}

Registry stack:
  enabled: ${LOCAL_REGISTRY_ENABLED}
  push:    localhost:${LOCAL_REGISTRY_DEV_PORT}
  consume: k3d-${LOCAL_REGISTRY_PROXY_NAME}:${LOCAL_REGISTRY_CLUSTER_PORT}
EOF
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

build_hosts_file_without_entry() {
  local name="$1"
  local fqdn="$2"
  local temp_file="$3"

  if [[ -f /etc/hosts ]]; then
    awk -v marker="k3d-ecosystem:${name}" -v fqdn="${fqdn}" '
      {
        if (index($0, marker) > 0) {
          next
        }

        remove_line = 0
        token_count = split($0, parts, /[[:space:]]+/)
        for (i = 1; i <= token_count; i++) {
          if (parts[i] ~ /^#/) {
            break
          }
          if (parts[i] == fqdn) {
            remove_line = 1
            break
          }
        }

        if (!remove_line) {
          print
        }
      }
    ' /etc/hosts > "${temp_file}"
  else
    : > "${temp_file}"
  fi
}

warn_hosts_management_failure() {
  local action="$1"
  local host_ip="$2"
  local fqdn="$3"

  echo "warning: failed to ${action} /etc/hosts entry for ${fqdn}" >&2
  if [[ "${action}" == "add" ]]; then
    echo "manual command: sudo sh -c 'echo \"${host_ip} ${fqdn}\" >> /etc/hosts'" >&2
  else
    echo "manual cleanup may still be required in /etc/hosts" >&2
  fi
}

ensure_host_entry() {
  local name="$1"
  local fqdn="$2"
  local host_ip="$3"

  if [[ "${MANAGE_HOSTS_FILE}" != "true" ]]; then
    return 0
  fi

  local temp_file
  temp_file="$(mktemp)"

  build_hosts_file_without_entry "${name}" "${fqdn}" "${temp_file}"
  printf '%s %s # k3d-ecosystem:%s\n' "${host_ip}" "${fqdn}" "${name}" >> "${temp_file}"

  if ! write_hosts_file "${temp_file}"; then
    rm -f "${temp_file}"
    warn_hosts_management_failure "add" "${host_ip}" "${fqdn}"
    return 0
  fi

  rm -f "${temp_file}"
}

remove_host_entry() {
  local name="$1"
  local fqdn="$2"
  local host_ip="$3"

  if [[ "${MANAGE_HOSTS_FILE}" != "true" ]]; then
    return 0
  fi

  local temp_file
  temp_file="$(mktemp)"

  build_hosts_file_without_entry "${name}" "${fqdn}" "${temp_file}"

  if ! write_hosts_file "${temp_file}"; then
    rm -f "${temp_file}"
    warn_hosts_management_failure "remove" "${host_ip}" "${fqdn}"
    return 0
  fi

  rm -f "${temp_file}"
}

open_url() {
  local url="$1"

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 &
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "${url}" >/dev/null 2>&1 &
    return 0
  fi

  if command -v gio >/dev/null 2>&1; then
    gio open "${url}" >/dev/null 2>&1 &
    return 0
  fi

  echo "no supported URL opener found for ${url}" >&2
  return 1
}

next_free_host_ip() {
  local used_ips
  used_ips="$(k3d cluster list -o json | jq -r '.[].nodes[] | select(.role == "server") | .serverOpts.kubeAPI.Binding.HostIp // empty')"

  local octet
  for octet in $(seq 2 254); do
    local candidate="127.0.0.${octet}"
    if ! grep -Fxq "${candidate}" <<< "${used_ips}"; then
      printf '%s' "${candidate}"
      return 0
    fi
  done

  echo "no free loopback IP found in 127.0.0.0/24" >&2
  exit 1
}

next_free_api_port() {
  local start_port="${K3D_API_PORT_START:-6550}"
  local used_ports
  used_ports="$(k3d cluster list -o json | jq -r '.[].nodes[] | select(.role == "server") | .serverOpts.kubeAPI.Binding.HostPort // empty')"

  local port
  for port in $(seq "${start_port}" 6999); do
    if ! grep -Fxq "${port}" <<< "${used_ports}"; then
      printf '%s' "${port}"
      return 0
    fi
  done

  echo "no free API port found starting at ${start_port}" >&2
  exit 1
}

write_instance_env() {
  local name="$1"
  local env_file="$2"
  local fqdn="$3"
  local host_ip="$4"
  local api_port="$5"
  local kubeconfig_path="$6"
  local coredns_manifest_path="$7"

  cat > "${env_file}" <<EOF
# Generated by k3d/ecosystem.sh for ecosystem '${name}'
K3D_CLUSTER_NAME="${name}"
K3D_HOST_IP="${host_ip}"
K3D_API_PORT="${api_port}"
K3D_HTTP_PORT="80"
K3D_HTTPS_PORT="443"
FQDN="${fqdn}"
KUBECONFIG_PATH="${kubeconfig_path}"
K3D_COREDNS_CUSTOM_MANIFEST_PATH="${coredns_manifest_path}"
EOF
}

write_coredns_custom_manifest() {
  local manifest_file="$1"
  local fqdn="$2"

  cat > "${manifest_file}" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  ces-fqdn.override: |
    rewrite name exact ${fqdn} ces-loadbalancer.ecosystem.svc.cluster.local
EOF
}

create_ecosystem() {
  local name="$1"
  validate_name "${name}"
  load_global_config

  local env_file
  env_file="$(instance_env_file "${name}")"

  if [[ -f "${env_file}" ]]; then
    echo "instance env already exists: ${env_file}" >&2
    exit 1
  fi

  if cluster_exists "${name}"; then
    echo "k3d cluster '${name}' already exists" >&2
    exit 1
  fi

  local fqdn="${name}.${BASE_DOMAIN}"
  local host_ip
  host_ip="$(next_free_host_ip)"
  local api_port
  api_port="$(next_free_api_port)"
  local kubeconfig_path="${KUBECONFIG_DIRECTORY}/${fqdn}"
  local coredns_manifest_file
  coredns_manifest_file="$(instance_coredns_manifest_file "${name}")"

  write_coredns_custom_manifest "${coredns_manifest_file}" "${fqdn}"
  write_instance_env "${name}" "${env_file}" "${fqdn}" "${host_ip}" "${api_port}" "${kubeconfig_path}" "${coredns_manifest_file}"

  if [[ "${LOCAL_REGISTRY_ENABLED}" == "true" ]]; then
    "${REGISTRY_SCRIPT}" start >/dev/null
  fi

  run_with_instance_env "${env_file}" env K3D_SKIP_NEXT_STEPS=true "${CLUSTER_SCRIPT}" create
  "${INSTALL_SCRIPT}" "${env_file}"
  ensure_host_entry "${name}" "${fqdn}" "${host_ip}"
  print_ecosystem_summary "${name}" "${fqdn}" "${kubeconfig_path}"
}

open_ecosystem() {
  local name="$1"
  load_global_config_if_present

  local env_file
  env_file="$(instance_env_file "${name}")"
  if [[ ! -f "${env_file}" ]]; then
    echo "ecosystem '${name}' is not managed; cannot determine URL" >&2
    exit 1
  fi

  local fqdn
  fqdn="$(get_env_value "${env_file}" FQDN)"
  local host_ip
  host_ip="$(get_env_value "${env_file}" K3D_HOST_IP)"

  if [[ -z "${fqdn}" ]]; then
    echo "ecosystem '${name}' has no configured FQDN" >&2
    exit 1
  fi

  ensure_host_entry "${name}" "${fqdn}" "${host_ip}"

  local url="https://${fqdn}"
  echo "Opening ${url}"
  open_url "${url}"
}

start_ecosystem() {
  local name="$1"
  load_global_config_if_present
  local env_file
  env_file="$(instance_env_file "${name}")"

  if [[ "${LOCAL_REGISTRY_ENABLED}" == "true" ]]; then
    "${REGISTRY_SCRIPT}" start >/dev/null
  fi

  k3d cluster start "${name}"

  if [[ -f "${env_file}" ]]; then
    run_with_instance_env "${env_file}" "${CLUSTER_SCRIPT}" kubeconfig
    ensure_host_entry \
      "${name}" \
      "$(get_env_value "${env_file}" FQDN)" \
      "$(get_env_value "${env_file}" K3D_HOST_IP)"
  fi
}

stop_ecosystem() {
  local name="$1"
  k3d cluster stop "${name}"
}

delete_ecosystem() {
  local name="$1"
  load_global_config_if_present
  local env_file
  env_file="$(instance_env_file "${name}")"

  if [[ -f "${env_file}" ]]; then
    local fqdn
    fqdn="$(get_env_value "${env_file}" FQDN)"
    local host_ip
    host_ip="$(get_env_value "${env_file}" K3D_HOST_IP)"
    local coredns_manifest_file
    coredns_manifest_file="$(get_env_value "${env_file}" K3D_COREDNS_CUSTOM_MANIFEST_PATH)"
    if cluster_exists "${name}"; then
      run_with_instance_env "${env_file}" "${CLUSTER_SCRIPT}" delete
    else
      local kubeconfig_path
      kubeconfig_path="$(get_env_value "${env_file}" KUBECONFIG_PATH)"
      rm -f "${kubeconfig_path}"
    fi
    remove_host_entry "${name}" "${fqdn}" "${host_ip}"
    rm -f "${coredns_manifest_file}"
    rm -f "${env_file}"
  else
    k3d cluster delete "${name}"
  fi
}

list_ecosystems() {
  local cluster_json
  cluster_json="$(k3d cluster list -o json)"

  declare -A status_by_name=()
  declare -A host_ip_by_name=()
  declare -A api_port_by_name=()
  declare -A managed_by_name=()
  declare -A url_by_name=()
  declare -A kubeconfig_by_name=()

  while IFS=$'\t' read -r name status host_ip api_port; do
    [[ -n "${name}" ]] || continue
    status_by_name["${name}"]="${status}"
    host_ip_by_name["${name}"]="${host_ip}"
    api_port_by_name["${name}"]="${api_port}"
  done < <(jq -r '.[] | [.name, (if .serversRunning > 0 then "running" else "stopped" end), ([.nodes[] | select(.role == "server") | .serverOpts.kubeAPI.Binding.HostIp // empty][0] // ""), ([.nodes[] | select(.role == "server") | .serverOpts.kubeAPI.Binding.HostPort // empty][0] // "")] | @tsv' <<< "${cluster_json}")

  shopt -s nullglob
  local env_file
  for env_file in "${ENV_DIR}"/*.env; do
    local name
    name="$(get_env_value "${env_file}" K3D_CLUSTER_NAME)"
    [[ -n "${name}" ]] || continue
    managed_by_name["${name}"]="yes"
    local fqdn
    fqdn="$(get_env_value "${env_file}" FQDN)"
    if [[ -n "${fqdn}" ]]; then
      url_by_name["${name}"]="https://${fqdn}"
    fi
    kubeconfig_by_name["${name}"]="$(get_env_value "${env_file}" KUBECONFIG_PATH)"
    if [[ -z "${status_by_name[${name}]:-}" ]]; then
      status_by_name["${name}"]="absent"
    fi
  done
  shopt -u nullglob

  if [[ "${#status_by_name[@]}" -eq 0 ]]; then
    echo "No local k3d ecosystems found."
    return 0
  fi

  printf '%-20s %-10s %-8s %-15s %-8s %-38s %s\n' "NAME" "STATUS" "MANAGED" "HOST_IP" "API" "URL" "KUBECONFIG"

  local name
  while IFS= read -r name; do
    printf '%-20s %-10s %-8s %-15s %-8s %-38s %s\n' \
      "${name}" \
      "${status_by_name[${name}]}" \
      "${managed_by_name[${name}]:-no}" \
      "${host_ip_by_name[${name}]:-}" \
      "${api_port_by_name[${name}]:-}" \
      "${url_by_name[${name}]:-}" \
      "${kubeconfig_by_name[${name}]:-}"
  done < <(printf '%s\n' "${!status_by_name[@]}" | sort)
}

main() {
  ensure_prerequisites

  local command="${1:-}"
  local name="${2:-}"

  case "${command}" in
    create)
      [[ -n "${name}" ]] || { usage; exit 1; }
      create_ecosystem "${name}"
      ;;
    open)
      [[ -n "${name}" ]] || { usage; exit 1; }
      open_ecosystem "${name}"
      ;;
    start)
      [[ -n "${name}" ]] || { usage; exit 1; }
      start_ecosystem "${name}"
      ;;
    stop)
      [[ -n "${name}" ]] || { usage; exit 1; }
      stop_ecosystem "${name}"
      ;;
    delete)
      [[ -n "${name}" ]] || { usage; exit 1; }
      delete_ecosystem "${name}"
      ;;
    list)
      list_ecosystems
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
