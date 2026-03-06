#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail


# Wait until the Component's Health status is available
# Args: <component_name> <namespace> [timeout_seconds]
wait_for_component_healthy() {
  local name="${1:-coponent}"
  local namespace="${2:-${CES_NAMESPACE}}"
  local timeout="${3:-900}" # default 15 minutes
  local interval=5
  local elapsed=0

  echo "Waiting for Component/${name} in namespace ${namespace} to reach Health=available (timeout: ${timeout}s)..."

  while true; do
    # Fetch the 'Health' status ("available"/"unavailable" or empty if not present)
    local status
    status="$(kubectl get component "${name}" -n "${namespace}" -o jsonpath='{.status.health}')"

    if [ "${status}" = "available" ]; then
      echo "Component/${name} Health=available."
      return 0
    fi

    if [ "${elapsed}" -ge "${timeout}" ]; then
      echo "Timeout waiting for Component/${name} Health=available. Last status: ${status:-<none>}" >&2
      return 1
    fi

    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done
}