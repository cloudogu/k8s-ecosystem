#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export NODE_CONFIG_FILE=/etc/ces/nodeconfig/k3sConfig.json
export K3S_DOCKER_REGISTRY_CONFIG_PATH=/etc/rancher/k3s
export K3S_DOCKER_REGISTRY_CONFIG_FILE="${K3S_DOCKER_REGISTRY_CONFIG_PATH}"/registries.yaml
export K3S_SYSTEMD_ENV_DIR=/etc/systemd/system
if [[ -e /etc/vagrant_box_build_time ]]; then
  export DEFAULT_USER=vagrant
else
  export DEFAULT_USER=ces-admin
fi

function waitForAnyServiceFile() {
  until [ -f "${K3S_SYSTEMD_ENV_DIR}/k3s.service" ] || [ -f "${K3S_SYSTEMD_ENV_DIR}/k3s-agent.service" ]; do
    echo "Waiting for k3s or k3s-agent service to exist. Try again in 5 seconds..."
    sleep 5
  done

  echo "Found k3s/k3s-agent service files"
}

function waitForConfigFile() {
  until [ -f "${NODE_CONFIG_FILE}" ]; do
    echo "Config file ${NODE_CONFIG_FILE} not available. Try again in 5 seconds..."
    sleep 5
  done

  echo "Found config file ${NODE_CONFIG_FILE}"
}

function runUpdateK3sConfiguration() {
  local configHasChanged="false"

  echo "Determining whether this is the main node or a worker..."
  if ls /etc/systemd/system/k3s-agent.service >/dev/null; then
    echo "This is a k3s agent/worker node"
    export K3S_SERVICE_NAME=k3s-agent
  else
    echo "This is a k3s main node"
    export K3S_SERVICE_NAME=k3s
  fi

  local k3sSystemEnvFile="${K3S_SYSTEMD_ENV_DIR}/${K3S_SERVICE_NAME}.service.env"
  local k3sSystemServiceFile="${K3S_SYSTEMD_ENV_DIR}/${K3S_SERVICE_NAME}.service"

  local hostName
  local nodeIp
  local nodeExternalIp
  local flannelIface
  hostName=$(cat /etc/hostname)
  echo "Hostname is ${hostName}"

  echo "Getting node-ip, node-external-ip and flannel-iface configurations for ${hostName} from ${NODE_CONFIG_FILE}..."
  nodeIp=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"node-ip\"" ${NODE_CONFIG_FILE})
  nodeExternalIp=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"node-external-ip\"" ${NODE_CONFIG_FILE})
  flannelIface=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"flannel-iface\"" ${NODE_CONFIG_FILE})
  echo "nodeIp = ${nodeIp}, nodeExternalIp = ${nodeExternalIp}, flannelIface = ${flannelIface}"

  if [[ ${nodeIp} == "null" ]] || [[ ${nodeExternalIp} == "null" ]] || [[ ${flannelIface} == "null" ]]; then
    echo "ERROR: node-ip, node-external-ip and/or flannel-iface configuration is null"
    exit 1
  fi

  echo "Checking if configuration has changed..."
  if [[ $(nodeIPHasChanged "${nodeIp}" "${k3sSystemServiceFile}") == "true" ]]; then
    configHasChanged="true"
    echo "NodeIP has changed"
    echo "Replacing node-ip in ${k3sSystemServiceFile} with ${nodeIp}..."
    replaceNodeIpInK3sServiceFile "${k3sSystemServiceFile}" "${nodeIp}"
  fi

  if [[ $(nodeExternalIPHasChanged "${nodeExternalIp}" "${k3sSystemEnvFile}" "${k3sSystemServiceFile}") == "true" ]]; then
    configHasChanged="true"
    echo "NodeExternalIP has changed"
    echo "Replacing node-external-ip in ${k3sSystemServiceFile} with ${nodeExternalIp}..."
    replaceNodeExternalIpInK3sServiceFile "${k3sSystemServiceFile}" "${nodeExternalIp}"
    if [[ ${K3S_SERVICE_NAME} == "k3s" ]]; then
      echo "Replacing K3S_EXTERNAL_IP in ${k3sSystemEnvFile} with ${nodeExternalIp}..."
      replaceNodeExternalIpInK3sEnvFile "${k3sSystemEnvFile}" "${nodeExternalIp}"
    fi
  fi

  if [[ $(flannelIfaceHasChanged "${flannelIface}" "${k3sSystemServiceFile}") == "true" ]]; then
    configHasChanged="true"
    echo "FlannelIface has changed"
    echo "Replacing flannel-iface in ${k3sSystemServiceFile} with ${flannelIface}"
    replaceFlannelIfaceInK3sServiceFile "${k3sSystemServiceFile}" "${flannelIface}"
  fi

  if [[ ${K3S_SERVICE_NAME} == "k3s-agent" ]]; then
    mainNodeIp=$(jq -r ".nodes[] | select(.isMainNode==true) | .\"node-ip\"" ${NODE_CONFIG_FILE})
    if [[ $(mainNodeIpHasChanged ${k3sSystemEnvFile} "${mainNodeIp}") == "true" ]]; then
      configHasChanged="true"
      echo "Main node IP has changed"
      echo "Replacing K3S_URL in ${k3sSystemEnvFile} with ${mainNodeIp}..."
      replaceK3sUrlInK3sEnvFile "${k3sSystemEnvFile}" "${mainNodeIp}"
    fi
  fi

  if [[ ${configHasChanged} == "true" ]]; then
    reloadDaemon
    restartK3s
  else
    echo "Configuration has not changed"
  fi
}

function reloadDaemon() {
  echo "Reloading systemctl daemon..."
  systemctl daemon-reload
}

function restartK3s() {
  echo "Restarting ${K3S_SERVICE_NAME} service..."
  systemctl restart ${K3S_SERVICE_NAME}
}

function nodeIPHasChanged() {
  local nodeIp="${1}"
  local k3sSystemdServiceFile="${2}"

  if grep "node-ip" "${k3sSystemdServiceFile}" | grep "${nodeIp}"; then
    echo "false"
  else
    echo "true"
  fi
}

function mainNodeIpHasChanged() {
  local k3sEnvFile="${1}"
  local mainNodeIp="${2}"

  if grep "K3S_URL" "${k3sEnvFile}" | grep "${mainNodeIp}"; then
    echo "false"
  else
    echo "true"
  fi
}

function nodeExternalIPHasChanged() {
  local nodeExternalIp="${1}"
  local k3sSystemdEnvFile="${2}"
  local k3sSystemdServiceFile="${3}"

  if grep "external-ip" "${k3sSystemdServiceFile}" | grep "${nodeExternalIp}"; then
    if grep "K3S_EXTERNAL_IP" "${k3sSystemdEnvFile}" | grep "${nodeExternalIp}"; then
      echo "false"
    else
      echo "true"
    fi
  else
    echo "true"
  fi
}

function flannelIfaceHasChanged() {
  local flannelIface="${1}"
  local k3sSystemdServiceFile="${2}"

  if grep "flannel-iface" "${k3sSystemdServiceFile}" | grep "${flannelIface}"; then
    echo "false"
  else
    echo "true"
  fi
}

function replaceNodeIpInK3sServiceFile() {
  local k3sServiceFile="${1}"
  local nodeIp="${2}"
  sed -i "s|\(--node-ip\)=.*$|\1=${nodeIp}' \\\|g" "${k3sServiceFile}"
}

function replaceNodeExternalIpInK3sServiceFile() {
  local k3sServiceFile="${1}"
  local nodeExternalIp="${2}"
  sed -i "s|\(--node-external-ip\)=.*$|\1=${nodeExternalIp}' \\\|g" "${k3sServiceFile}"
}

function replaceNodeExternalIpInK3sEnvFile() {
  local k3sEnvFile="${1}"
  local nodeExternalIp="${2}"
  sed -i "s|^\(K3S_EXTERNAL_IP\)=.\+$|\1='${nodeExternalIp}'|g" "${k3sEnvFile}"
}

function replaceFlannelIfaceInK3sServiceFile() {
  local k3sServiceFile="${1}"
  local flannelIface="${2}"
  sed -i "s|\(--flannel-iface\)=.*$|\1=${flannelIface}' \\\|g" "${k3sServiceFile}"
}

function replaceK3sUrlInK3sEnvFile() {
  local k3sEnvFile="${1}"
  local mainNodeIp="${2}"
  sed -i "s|^\(K3S_URL\)=.\+$|\1='https://${mainNodeIp}:6443'|g" "${k3sEnvFile}"
}

function installK3s() {
  local nodeIp nodeExternalIp flannelIface cesNamespace isMainNode k3sToken hostName nodeLabels="" nodeTaints=""
  hostName=$(cat /etc/hostname)
  echo "Getting node-ip, node-external-ip and flannel-iface configurations for ${hostName} from ${NODE_CONFIG_FILE}..."
  nodeIp=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"node-ip\"" ${NODE_CONFIG_FILE})
  nodeExternalIp=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"node-external-ip\"" ${NODE_CONFIG_FILE})
  flannelIface=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"flannel-iface\"" ${NODE_CONFIG_FILE})
  cesNamespace=$(jq -r ".\"ces-namespace\"" ${NODE_CONFIG_FILE})
  isMainNode=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"isMainNode\"" ${NODE_CONFIG_FILE})
  nodeLabels=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"node-labels\" | if (. == null) then \"\" else join(\" \") end" ${NODE_CONFIG_FILE})
  nodeTaints=$(jq -r ".nodes[] | select(.name == \"${hostName}\") | .\"node-taints\" | if (. == null) then \"\" else join(\" \") end" ${NODE_CONFIG_FILE})
  k3sToken=$(jq -r ".\"k3s-token\"" ${NODE_CONFIG_FILE})
  echo "nodeIp = ${nodeIp}, nodeExternalIp = ${nodeExternalIp}, flannelIface = ${flannelIface}, nodeLabels = [$nodeLabels], nodeTaints = [$nodeTaints]"

  if [[ -z ${nodeIp} ]] || [[ -z ${nodeExternalIp} ]] || [[ -z ${flannelIface} ]]; then
    echo "ERROR: node-ip, node-external-ip and/or flannel-iface configuration is empty"
    exit 1
  fi

  if [[ ${k3sToken} == "null" ]] || [[ -z ${k3sToken} ]]; then
    echo "ERROR: The k3s token setting does not exist or is empty!"
    exit 1
  fi

  if [[ ${cesNamespace} == "null" ]] || [[ -z ${cesNamespace} ]]; then
    echo "ERROR: The ces namespace setting does not exist or is empty!"
    exit 1
  fi

  if [[ ${isMainNode} == "true" ]]; then
    echo "This machine has been configured as a main node"
    /usr/sbin/setupMainNode.sh "${nodeIp}" "${nodeExternalIp}" "${flannelIface}" "${k3sToken}" "${DEFAULT_USER}" "${nodeLabels}" "${nodeTaints}"
    /usr/sbin/createNamespace.sh "${cesNamespace}"
  else
    echo "This machine has been configured as a worker node"
    local mainNodeIp
    local mainNodePort
    mainNodeIp=$(jq -r '.nodes[]| select(.isMainNode==true)|."node-external-ip"' ${NODE_CONFIG_FILE})
    mainNodePort=6443
    /usr/sbin/k3s-worker.sh "${nodeIp}" "${nodeExternalIp}" "${flannelIface}" "${mainNodeIp}" ${mainNodePort} "${k3sToken}" "${DEFAULT_USER}" "${nodeLabels}" "${nodeTaints}"
  fi
}

function configureDockerRegistryMirrors() {
  local config
  echo "Getting docker registry configuration from ${NODE_CONFIG_FILE}..."

  config=$(jq -r ".\"docker-registry-configuration\"" ${NODE_CONFIG_FILE})
  if [[ "${config}" == "null" ]]; then
    echo "No docker registry configuration found"
    if [[ -f "${K3S_DOCKER_REGISTRY_CONFIG_FILE}" ]]; then
      echo "Removing ${K3S_DOCKER_REGISTRY_CONFIG_FILE}..."
      rm "${K3S_DOCKER_REGISTRY_CONFIG_FILE}"
    fi
    return
  fi

  echo "Writing docker registry configuration into ${K3S_DOCKER_REGISTRY_CONFIG_FILE}..."
  mkdir -p "${K3S_DOCKER_REGISTRY_CONFIG_PATH}"
  echo "${config}" | yq -P > "${K3S_DOCKER_REGISTRY_CONFIG_FILE}"
}

# run script only if called but not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  waitForConfigFile
  configureDockerRegistryMirrors
  if [[ -e /var/lib/rancher/k3s/agent/images/k3sVersion ]]; then
    installK3s
    rm /var/lib/rancher/k3s/agent/images/k3sVersion
  else
    echo "Updating k3s configuration..."
    waitForAnyServiceFile
    runUpdateK3sConfiguration "$@"
  fi
fi
