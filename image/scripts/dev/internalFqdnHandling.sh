#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Wait until a Service has a cluster IP.
# Args: <service_name> <namespace> [timeout_seconds]
wait_for_service_cluster_ip() {
  local service_name="$1"
  local namespace="$2"
  local timeout="${3:-300}"
  local interval=5
  local elapsed=0

  while true; do
    local cluster_ip
    cluster_ip="$(kubectl get svc "${service_name}" -n "${namespace}" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"

    if [ -n "${cluster_ip}" ] && [ "${cluster_ip}" != "None" ]; then
      printf '%s' "${cluster_ip}"
      return 0
    fi

    if [ "${elapsed}" -ge "${timeout}" ]; then
      echo "Timeout waiting for Service/${service_name} cluster IP in namespace ${namespace}" >&2
      return 1
    fi

    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done
}

# Ensure the target CES namespace exists.
ensure_namespace() {
  if kubectl get namespace "${CES_NAMESPACE}" >/dev/null 2>&1; then
    echo "Namespace '${CES_NAMESPACE}' already exists."
  else
    echo "Creating namespace '${CES_NAMESPACE}'..."
    kubectl create namespace "${CES_NAMESPACE}"
  fi
}

# Ensure the cluster-internal FQDN resolves to the CES loadbalancer service.
ensure_internal_fqdn_dns() {
  if [ "${ENABLE_INTERNAL_FQDN_DNS}" != "true" ]; then
    return 0
  fi

  local coredns_namespace="kube-system"
  local coredns_configmap="coredns"
  local service_name="ces-loadbalancer"
  local service_ip
  service_ip="$(wait_for_service_cluster_ip "${service_name}" "${CES_NAMESPACE}" 300)"

  local nodehosts
  nodehosts="$(kubectl get configmap "${coredns_configmap}" -n "${coredns_namespace}" -o jsonpath='{.data.NodeHosts}' 2>/dev/null || true)"

  if [ -z "${nodehosts}" ]; then
    echo "CoreDNS NodeHosts not found; skipping internal FQDN DNS setup."
    return 0
  fi

  local updated_nodehosts
  updated_nodehosts="$(
    {
      printf '%s\n' "${nodehosts}" | awk -v fqdn="${fqdn}" '$2 != fqdn'
      printf '%s %s\n' "${service_ip}" "${fqdn}"
    } | awk 'NF && !seen[$0]++'
  )"

  local patch
  patch="$(jq -n --arg hosts "${updated_nodehosts}" '{data:{NodeHosts:$hosts}}')"

  echo "Ensuring internal DNS mapping ${fqdn} -> ${service_ip} in CoreDNS..."
  kubectl patch configmap "${coredns_configmap}" -n "${coredns_namespace}" --type merge -p "${patch}" >/dev/null
  kubectl rollout restart deployment coredns -n "${coredns_namespace}" >/dev/null
  kubectl rollout status deployment coredns -n "${coredns_namespace}" --timeout=120s
}

# Only patch internal DNS once the CES loadbalancer service exists.
ensure_internal_fqdn_dns_if_service_exists() {
  if [ "${ENABLE_INTERNAL_FQDN_DNS}" != "true" ]; then
    return 0
  fi

  if kubectl get svc ces-loadbalancer -n "${CES_NAMESPACE}" >/dev/null 2>&1; then
    ensure_internal_fqdn_dns
  else
    echo "Service 'ces-loadbalancer' not found yet; skipping internal FQDN DNS setup."
  fi
}
