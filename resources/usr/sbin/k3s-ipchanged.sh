#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export K3S_SYSTEMD_ENV_DIR=/etc/systemd/system
export K3S_SYSTEMD_ENV_FILE="${K3S_SYSTEMD_ENV_DIR}/k3s.service.env"
export K3S_SYSTEMD_SERVICE_FILE="${K3S_SYSTEMD_ENV_DIR}/k3s.service"

function runReplaceExternalIpAddress() {
    externalIpAddress="$(getExternalIpAddress)"
    assertNonEmpty "${externalIpAddress}"

    replaceIpAddressInK3sConfig "${K3S_SYSTEMD_ENV_FILE}" "${externalIpAddress}"
    replaceIpAddressInK3sService "${K3S_SYSTEMD_SERVICE_FILE}" "${externalIpAddress}"

    systemctl daemon-reload
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

function assertNonEmpty() {
    local externalIpAddress="${1}"

    [[ "${externalIpAddress}" != "" ]]
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