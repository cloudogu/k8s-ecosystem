#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

INTERMEDIATE_DIR=/home/${USERNAME}/resources
TARGET_DIR=/

function runInstallCustomServiceFiles() {
    local filePaths="etc/systemd/system/k3s-conf.service usr/sbin/k3s-conf.sh usr/sbin/createNamespace.sh usr/sbin/installLonghorn.sh usr/sbin/setupMainNode.sh usr/sbin/k3s-worker.sh"

    echo "Moving all files from ${INTERMEDIATE_DIR} to ${TARGET_DIR}"
    for filePath in ${filePaths}; do
        local targetPath="${TARGET_DIR}${filePath}"
        mv "${INTERMEDIATE_DIR}/${filePath}" "${targetPath}"
        chown root:root "${targetPath}"
        
        if [[ "${filePath}" =~ \.sh ]]; then
            chmod 0744 "${targetPath}"
        fi
    done

    systemctl enable k3s-conf

    rm -rf "${INTERMEDIATE_DIR}"
}

# run script only if called but not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    runInstallCustomServiceFiles "$@"
fi