#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

INTERMEDIATE_DIR=/home/ces-admin/resources
TARGET_DIR=/

function runInstallCustomServiceFiles() {
    local filePaths="etc/systemd/system/k3s-ipchanged.service usr/sbin/k3s-ipchanged.sh"

    echo "Moving all files from ${INTERMEDIATE_DIR} to ${TARGET_DIR}"
    for filePath in ${filePaths}; do
        local targetPath="${TARGET_DIR}${filePath}"
        mv "${INTERMEDIATE_DIR}/${filePath}" "${targetPath}"
        chown root:root "${targetPath}"
        
        if [[ "${filePath}" =~ \.sh ]]; then
            chmod 0744 "${targetPath}"
        fi
    done

    systemctl enable k3s-ipchanged

    rm -rf "${INTERMEDIATE_DIR}"
}

# run script only if called but not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    runInstallCustomServiceFiles "$@"
fi