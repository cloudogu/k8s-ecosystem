#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SSH_MOUNT_PATH=/etc/ces
SSH_KEYS_FILE=${SSH_MOUNT_PATH}/authorized_keys
SSHD_CONFIG_FILE=/etc/ssh/sshd_config

disableUserPasswordLogin() {
  sudo sed -i "s|^[#.*]*ChallengeResponseAuthentication yes.*|ChallengeResponseAuthentication no|g" "${SSHD_CONFIG_FILE}"
  sudo sed -i "s|^[#.*]*PasswordAuthentication yes.*|PasswordAuthentication no|g" "${SSHD_CONFIG_FILE}"
  sudo sed -i "s|^[#.*]*UsePAM yes.*|UsePAM no|g" "${SSHD_CONFIG_FILE}"
  sudo sed -i "s|^[#.*]*PermitRootLogin .*|PermitRootLogin prohibit-password|g" "${SSHD_CONFIG_FILE}"
}

authorizedMountedSSHKey() {
  sudo sed -i "s|^[#.*]*AuthorizedKeysFile.*|AuthorizedKeysFile .ssh/authorized_keys ${SSH_KEYS_FILE}|g" "${SSHD_CONFIG_FILE}"
}


echo "Disabling username/password authentication for SSH"
disableUserPasswordLogin

echo "Enabling usage of authorized keys file ${SSH_KEYS_FILE}"
sudo mkdir -p ${SSH_MOUNT_PATH}
authorizedMountedSSHKey

echo "Restarting sshd service"
sudo systemctl restart sshd.service