#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

BLUEPRINT_YAML_TEMPLATE="image/scripts/dev/blueprint.yaml.tpl"
BLUEPRINT_YAML="image/scripts/dev/.blueprint.yaml"
BLUEPRINT_OVERRIDE_YAML=".blueprint-override.yaml"

# Build and apply a .blueprint.yaml with latest dogu versions based on blueprint.yaml.tpl
# Requires: jq, yq (v4+), curl
# Args: <dogu_registry_username> <dogu_registry_password> <fqdn>
patch_and_apply_blueprint_with_latest_versions() {
  local username="$1"
  local password="$2"
  local fqdn="$3"

  # Ig .blueprint-override.yaml exists, use this
  if [ -f "$BLUEPRINT_OVERRIDE_YAML" ]; then
    echo "applying $BLUEPRINT_OVERRIDE_YAML..."
    kubectl apply -f "$BLUEPRINT_YAML"
    return 0
  fi



  # Extract dogu names from template
  mapfile -t dogus < <(yq -r '.spec.blueprint.dogus[].name' "$BLUEPRINT_YAML_TEMPLATE")

  # Prepare a temporary yq expression to update versions
  local yq_expr=""
  local idx=0
  for dogu in "${dogus[@]}"; do
    # Fetch latest version for each dogu
    local ver
    if ! ver="$(get_latest_dogu_version "$dogu" "$username" "$password")" || [ -z "$ver" ] || [ "$ver" = "null" ]; then
      echo "Warning: Could not resolve latest version for $dogu; keeping template version."
      idx=$((idx+1))
      continue
    fi
    # Build yq update expression
    if [ -n "$yq_expr" ]; then
      yq_expr+=" | "
    fi
    yq_expr+=".spec.blueprint.dogus[$idx].version = \"$ver\""
    idx=$((idx+1))
  done

  # If both certificate files exist, patch certificate/type to external
  if [ -f "$CERTIFICATE_CRT_FILE" ] || [ -f "$CERTIFICATE_KEY_FILE" ]; then
    echo "certificate found. setting certificate/type to external"
    if [ -n "$yq_expr" ]; then
      yq_expr+=" | "
    fi
    yq_expr+="(.spec.blueprint.config.global[] | select(.key == \"certificate/type\") | .value) = \"external\""
  fi

  # Set fqdn
  echo "setting fqdn in global-config to $fqdn"
  if [ -n "$yq_expr" ]; then
    yq_expr+=" | "
  fi
  yq_expr+="(.spec.blueprint.config.global[] | select(.key == \"fqdn\") | .value) = \"${fqdn}\""

  # If we have updates, apply them; otherwise copy template
  if [ -n "$yq_expr" ]; then
    yq eval "$yq_expr" "$BLUEPRINT_YAML_TEMPLATE" > "$BLUEPRINT_YAML"
  else
    cp "$BLUEPRINT_YAML_TEMPLATE" "$BLUEPRINT_YAML"
  fi

  kubectl apply -f "$BLUEPRINT_YAML"

  echo "applying $BLUEPRINT_YAML with latest dogu versions."
}

# Wait until the Blueprint's Completed condition is True
# Args: <blueprint_name> <namespace> [timeout_seconds]
wait_for_blueprint_completed() {
  local name="${1:-blueprint}"
  local namespace="${2:-${CES_NAMESPACE}}"
  local timeout="${3:-900}" # default 15 minutes
  local interval=5
  local elapsed=0

  echo "Waiting for Blueprint/${name} in namespace ${namespace} to reach Completed=True (timeout: ${timeout}s)..."

  while true; do
    # Fetch the 'Completed' condition status ("True"/"False"/"Unknown" or empty if not present)
    local status
    status="$(kubectl get blueprint "${name}" -n "${namespace}" -o json \
      | jq -r '.status.conditions[]? | select(.type=="Completed") | .status' 2>/dev/null)"

    if [ "${status}" = "True" ]; then
      echo "Blueprint/${name} Completed=True."
      return 0
    fi

    if [ "${elapsed}" -ge "${timeout}" ]; then
      echo "Timeout waiting for Blueprint/${name} Completed=True. Last status: ${status:-<none>}" >&2
      return 1
    fi

    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done
}

# Set the Blueprint's spec.stopped to true
# Args: <blueprint_name> <namespace>
set_blueprint_stopped() {
  local name="${1:-blueprint}"
  local namespace="${2:-${CES_NAMESPACE}}"
  local stopped="true"

  echo "Patching Blueprint/${name} in ${namespace}: spec.stopped=${stopped}"
  kubectl patch blueprint "${name}" -n "${namespace}" --type merge -p "{\"spec\":{\"stopped\":${stopped}}}"
}

# wait for Completed=True, then set spec.stopped=true
# Args: <blueprint_name> <namespace> [timeout_seconds]
wait_and_stop_blueprint() {
  local name="${1:-blueprint}"
  local namespace="${2:-${CES_NAMESPACE}}"
  local timeout="${3:-600}"

  if wait_for_blueprint_completed "${name}" "${namespace}" "${timeout}"; then
    set_blueprint_stopped "${name}" "${namespace}"
  else
    return 1
  fi
}