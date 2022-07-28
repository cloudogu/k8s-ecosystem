#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export NODE_CONFIG_FILE=/etc/ces/nodeconfig/k3sConfig.json
export K3S_SYSTEMD_ENV_DIR=/etc/systemd/system

function runUpdatek3sConfiguration() {
    local configHasChanged="false"

    echo "Determining whether this is the main host or a worker..."
    if ls /etc/systemd/system | grep agent > /dev/null; then
        echo "This is a k3s agent/worker node"
        export K3S_SERVICE_NAME=k3s-agent
    else
        echo "This is a k3s main node"
        export K3S_SERVICE_NAME=k3s
    fi
    export K3S_SYSTEMD_ENV_FILE="${K3S_SYSTEMD_ENV_DIR}/${K3S_SERVICE_NAME}.service.env"
    export K3S_SYSTEMD_SERVICE_FILE="${K3S_SYSTEMD_ENV_DIR}/${K3S_SERVICE_NAME}.service"

    echo "Getting hostname..."
    hostname=$(cat /etc/hostname)
    echo "Hostname is ${hostname}"

    echo "Getting node-ip, node-external-ip and flannel-iface configurations for ${hostname} from ${NODE_CONFIG_FILE}..."
    nodeIp=$(jq -r ".\"${hostname}\" | .\"node-ip\"" ${NODE_CONFIG_FILE})
    nodeExternalIp=$(jq -r ".\"${hostname}\" | .\"node-external-ip\"" ${NODE_CONFIG_FILE})
    flannelIface=$(jq -r ".\"${hostname}\" | .\"flannel-iface\"" ${NODE_CONFIG_FILE})
    echo "nodeIp = ${nodeIp}, nodeExternalIp = ${nodeExternalIp}, flannelIface = ${flannelIface}"

    echo "Checking if configuration has changed..."
    if [[ $(nodeIPHasChanged "${nodeIp}" "${K3S_SYSTEMD_SERVICE_FILE}") == "true" ]]; then
        configHasChanged="true"
        echo "NodeIP has changed"
        echo "Replacing node-ip in ${K3S_SYSTEMD_SERVICE_FILE} with ${nodeIp}..."
        replaceNodeIpInK3sServiceFile "${K3S_SYSTEMD_SERVICE_FILE}" "${nodeIp}"
    fi
    if [[ $(nodeExternalIPHasChanged "${nodeExternalIp}" "${K3S_SYSTEMD_ENV_FILE}" "${K3S_SYSTEMD_SERVICE_FILE}") == "true" ]]; then
        configHasChanged="true"
        echo "NodeExternalIP has changed"
        echo "Replacing node-external-ip in ${K3S_SYSTEMD_SERVICE_FILE} with ${nodeExternalIp}..."
        replaceNodeExternalIpInK3sServiceFile "${K3S_SYSTEMD_SERVICE_FILE}" "${nodeExternalIp}"
        if [[ ${K3S_SERVICE_NAME} == "k3s" ]]; then
            echo "Replacing K3S_EXTERNAL_IP in ${K3S_SYSTEMD_ENV_FILE} with ${nodeExternalIp}..."
            replaceNodeExternalIpInK3sEnvFile "${K3S_SYSTEMD_ENV_FILE}" "${nodeExternalIp}"
        fi
    fi
    if [[ $(flannelIfaceHasChanged "${flannelIface}" "${K3S_SYSTEMD_SERVICE_FILE}") == "true" ]]; then
        configHasChanged="true"
        echo "FlannelIface has changed"
        echo "Replacing flannel-iface in ${K3S_SYSTEMD_SERVICE_FILE} with ${flannelIface}"
        replaceFlannelIfaceInK3sServiceFile "${K3S_SYSTEMD_SERVICE_FILE}" "${flannelIface}"
    fi
    if [[ ${K3S_SERVICE_NAME} == "k3s-agent" ]]; then
        mainNodeIp=$(jq -r ".[] | select(.isMainNode==true) | .\"node-ip\"" ${NODE_CONFIG_FILE})
        if [[ $(mainNodeIpHasChanged ${K3S_SYSTEMD_ENV_FILE} "${mainNodeIp}") == "true" ]]; then
            configHasChanged="true"
            echo "Main node IP has changed"
            echo "Replacing K3S_URL in ${K3S_SYSTEMD_ENV_FILE} with ${mainNodeIp}..."
            replaceK3sUrlInK3sEnvFile "${K3S_SYSTEMD_ENV_FILE}" "${mainNodeIp}"
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

    if grep "external-ip" "${k3sSystemdServiceFile}" | grep "${nodeExternalIp}" ; then
        if grep "K3S_EXTERNAL_IP" "${k3sSystemdEnvFile}" | grep "${nodeExternalIp}" ; then
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


# run script only if called but not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    runUpdatek3sConfiguration "$@"
fi