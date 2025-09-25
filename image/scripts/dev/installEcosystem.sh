#!/bin/bash
# This file is responsible to install or update the ces in the cluster.
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

BLUEPRINT_YAML_TEMPLATE="image/scripts/dev/blueprint.yaml.tpl"
BLUEPRINT_YAML="image/scripts/dev/.blueprint.yaml"

# --- Helpers (clean-code / duplication reduction) ---

# decode_if_b64 VAR -> echoes decoded value if input is base64, otherwise original
decode_if_b64() {
  local input="$1"
  if printf '%s' "$input" | base64 -d >/dev/null 2>&1; then
    printf '%s' "$input" | base64 -d
  else
    printf '%s' "$input"
  fi
}

# ensure_secret <name> <type> <namespace> --from-literal=key1=val1 [--from-literal=...]
# Usage example:
#   ensure_secret my-secret generic my-ns --from-literal=foo=bar --from-literal=baz=qux
ensure_secret() {
  local name="$1"; shift
  local type="$1"; shift
  local namespace="$1"; shift
  kubectl create secret "$type" "$name" \
    --namespace="$namespace" \
    "$@" \
    --dry-run=client -o yaml \
  | kubectl apply -f -
  echo "Secret \"$name\" ensured in namespace \"$namespace\"."
}

# ensure_configmap <name> <namespace> --from-literal=key=val ...
ensure_configmap() {
  local name="$1"; shift
  local namespace="$1"; shift
  kubectl create configmap "$name" \
    --namespace="$namespace" \
    "$@" \
    --dry-run=client -o yaml \
  | kubectl apply -f -
  echo "ConfigMap \"$name\" ensured in namespace \"$namespace\"."
}

# login_registry_helm <host> <username> <password>
login_registry_helm() {
  local host="$1"
  local user="$2"
  local pass_decoded
  pass_decoded="$(decode_if_b64 "$3")"
  printf '%s' "$pass_decoded" | helm registry login "$host" --username "$user" --password-stdin
}

# Fetch latest version string for a given dogu via the registry API
# Prints the version (e.g., 1.2.3-4) to stdout
get_latest_dogu_version() {
  local dogu="$1"
  local username="$2"
  local password_decoded
  password_decoded="$(decode_if_b64 "$3")"

  local auth_b64
  auth_b64="$(printf '%s:%s' "$username" "$password_decoded" | base64 | tr -d '\n')"
  # Expected API returns a list of versions ordered by recency;
  curl -fsSL -H "Authorization: Basic ${auth_b64}" \
    "https://dogu.cloudogu.com/api/v2/dogus/${dogu}/_versions" \
  | jq -r '.[0]'
}

# --- Functions ---

# Create or update the k8s-dogu-operator-dogu-registry Secret in the given namespace.
# Args: <url> <urlschema> <username> <password> <namespace>
ensure_dogu_registry_secret() {
  local url="$1"
  local urlschema="$2"
  local username="$3"
  local password_decoded
  password_decoded="$(decode_if_b64 "$4")"
  local namespace="$5"
  ensure_secret "k8s-dogu-operator-dogu-registry" generic "$namespace" \
    --from-literal=endpoint="$url" \
    --from-literal=urlschema="$urlschema" \
    --from-literal=username="$username" \
    --from-literal=password="$password_decoded"
}

# ensure_container_registry_secret <docker_server> <username> <password> <namespace>
ensure_container_registry_secret() {
  local server="$1"
  local username="$2"
  local password_decoded
  password_decoded="$(decode_if_b64 "$3")"
  local namespace="$4"
  ensure_secret "ces-container-registries" docker-registry "$namespace" \
    --docker-server="$server" \
    --docker-username="$username" \
    --docker-password="$password_decoded"
}

# ensure_helm_registry_config <host> <schema> <plain_http> <insecure_tls> <username> <password> <namespace>
ensure_helm_registry_config() {
  local host="$1"
  local schema="$2"
  local plain_http="$3"
  local insecure_tls="$4"
  local username="$5"
  local password_decoded
  password_decoded="$(decode_if_b64 "$6")"
  local namespace="$7"

  local auth_b64
  auth_b64="$(printf '%s:%s' "$username" "$password_decoded" | base64 | tr -d '\n')"

  ensure_configmap "component-operator-helm-repository" "$namespace" \
    --from-literal=endpoint="$host" \
    --from-literal=schema="$schema" \
    --from-literal=plainHttp="$plain_http" \
    --from-literal=insecureTls="$insecure_tls"

  ensure_secret "component-operator-helm-registry" generic "$namespace" \
    --from-literal=config.json="{\"auths\": {\"$host\": {\"auth\": \"$auth_b64\"}}}"
  echo "Helm registry config ensured (ConfigMap + Secret)."
}

# Build and apply a .blueprint.yaml with latest dogu versions based on blueprint.yaml.tpl
# Requires: jq, yq (v4+), curl
patch_and_apply_blueprint_with_latest_versions() {
  local username="${dogu_registry_username}"
  local password="${dogu_registry_password}"

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

  # If we have updates, apply them; otherwise copy template
  if [ -n "$yq_expr" ]; then
    yq eval "$yq_expr" "$BLUEPRINT_YAML_TEMPLATE" > "$BLUEPRINT_YAML"
  else
    cp "$BLUEPRINT_YAML_TEMPLATE" "$BLUEPRINT_YAML"
  fi

  kubectl apply -f "$BLUEPRINT_YAML"

  echo "Applies $BLUEPRINT_YAML with latest dogu versions."
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

  # Install Component CRD
  helm upgrade -i k8s-component-operator-crd "${helm_registry_schema}://registry.cloudogu.com/${helm_repository_namespace}/k8s-component-operator-crd" \
    --namespace="${CES_NAMESPACE}"

  # Install Blueprint CRD
  helm upgrade -i k8s-blueprint-operator-crd "${helm_registry_schema}://registry.cloudogu.com/testing/k8s/k8s-blueprint-operator-crd" \
    --version 1.3.0-dev.1757922891 \
    --namespace="${CES_NAMESPACE}"

  # Install ecosystem-core
  ADDITIONAL_VALUES_TEMPLATE=image/scripts/dev/additionalValues.yaml.tpl
  ADDITIONAL_VALUES_YAML=image/scripts/dev/.additionalValues.yaml
  cp ${ADDITIONAL_VALUES_TEMPLATE} ${ADDITIONAL_VALUES_YAML}
  helm upgrade -i ecosystem-core "${helm_registry_schema}://registry.cloudogu.com/testing/k8s/ecosystem-core" \
    --version 0.1.0-dev.1758116730 \
    --values ${ADDITIONAL_VALUES_YAML} \
    --namespace="${CES_NAMESPACE}"

  # Apply blueprint with latest dogu versions
  patch_and_apply_blueprint_with_latest_versions
}

# --- Main ---

# set environment for helm and kubectl
export KUBECONFIG="${HOME}/.kube/$kube_ctx_name"

echo "set default k8s namespace"
kubectl config set-context --current --namespace "${CES_NAMESPACE}"

echo "**** Executing installEcosystem.sh..."

applyResources

echo "**** Finished installEcosystem.sh"
