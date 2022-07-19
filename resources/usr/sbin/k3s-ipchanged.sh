#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export K3S_SYSTEMD_ENV_DIR=/etc/systemd/system
export K3S_SYSTEMD_ENV_FILE="${K3S_SYSTEMD_ENV_DIR}/k3s.service.env"
export K3S_SYSTEMD_SERVICE_FILE="${K3S_SYSTEMD_ENV_DIR}/k3s.service"

function runReplaceExternalIpAddress() {
    echo "Getting external IP address..."
    externalIpAddress="$(getExternalIpAddress)"
    echo "Waiting for non-empty IP..."
    waitForNonEmptyIP "${externalIpAddress}"
    echo "Replacing IP in ${K3S_SYSTEMD_ENV_FILE} with ${externalIpAddress}..."
    replaceIpAddressInK3sConfig "${K3S_SYSTEMD_ENV_FILE}" "${externalIpAddress}"
    echo "Replacing IP in ${K3S_SYSTEMD_SERVICE_FILE} with ${externalIpAddress}..."
    replaceIpAddressInK3sService "${K3S_SYSTEMD_SERVICE_FILE}" "${externalIpAddress}"
    echo "Reloading systemctl daemon..."
    systemctl daemon-reload
    echo "Restarting k3s service..."
    systemctl restart k3s
}

function replaceIpAddressInK3sConfig() {
    local k3sOverrideConfigFile="${1}"
    local externalIpAddress="${2}"
    echo "Using IP ${externalIpAddress} in K3s env file"

    sed -i "s|^\(K3S_EXTERNAL_IP\)=.\+$|\1='${externalIpAddress}'|g" "${k3sOverrideConfigFile}"
}

function replaceIpAddressInK3sService() {
    local k3sOverrideServiceFile="${1}"
    local externalIpAddress="${2}"
    echo "Using IP ${externalIpAddress} in K3s service file"

    # replace two node IP specific options at once
    sed -i "s|\(--node[-a-z]*-ip\)=.*$|\1=${externalIpAddress}' \\\|g" "${k3sOverrideServiceFile}"
}

function waitForNonEmptyIP() {
    local externalIpAddress="${1}"

    for (( i = 1; i <=24; i++ )); do
        if [[ "${externalIpAddress}" != "" ]]; then
            echo "IP is still empty (${i})"
            sleep 5
            externalIpAddress="$(getExternalIpAddress)"
        else
            break
        fi
    done
}

function getExternalIpAddress() {
    defaultNetworkInterface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')

    externalIpAddress=$(ip addr show "${defaultNetworkInterface}" | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    echo "${externalIpAddress}"
}

# run script only if called but not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    runReplaceExternalIpAddress "$@"
fi