#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CERTIFICATE_CRT_FILE=".vagrant/certs/k3ces.localdomain.crt"
CERTIFICATE_KEY_FILE=".vagrant/certs/k3ces.localdomain.key"

# --- Helpers ---

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

# ensure_initial_admin_password_secret <namespace>
ensure_initial_admin_password_secret() {
  local namespace="$1"
  ensure_secret "initial-admin-password" generic "$namespace" \
    --from-literal=admin-password="adminpw"
}

# ensure_certificate_secret <namespace>
ensure_certificate_secret() {
  local namespace="$1"

  if [ ! -f "$CERTIFICATE_CRT_FILE" ] || [ ! -f "$CERTIFICATE_KEY_FILE" ]; then
    echo "no certificate file found. certificate will be self-signed"
    return 0
  fi

  ensure_secret "ecosystem-certificate" generic "$namespace" \
    --from-file=tls.crt="$CERTIFICATE_CRT_FILE" \
    --from-file=tls.key="$CERTIFICATE_KEY_FILE"
}