#!/bin/bash
# This file is responsible to configure the ssh daemon started in the ecosystem. Generally it does the following things:
# - prevents authentication via username/password
# - enforces authentication based on public/private keys
# - optimizes the performance of the daemon
set -o errexit
set -o nounset
set -o pipefail

SSH_MOUNT_PATH=/etc/ces
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
SSH_KEYS_FILE=${SSH_MOUNT_PATH}/authorized_keys

# Disables the username and password authentication as we only support key based authentication.
disableUserPasswordLogin() {
  echo "**** Disabling username/password authentication in ssh daemon..."
  sudo sed -i "s|^[#.*]*ChallengeResponseAuthentication yes.*|ChallengeResponseAuthentication no|g" "${SSHD_CONFIG_FILE}"
  sudo sed -i "s|^[#.*]*PasswordAuthentication yes.*|PasswordAuthentication no|g" "${SSHD_CONFIG_FILE}"
  sudo sed -i "s|^[#.*]*UsePAM yes.*|UsePAM no|g" "${SSHD_CONFIG_FILE}"
  sudo sed -i "s|^[#.*]*PermitRootLogin .*|PermitRootLogin prohibit-password|g" "${SSHD_CONFIG_FILE}"
}

# Configure the file at path ${SSH_KEYS_FILE} to be used as an `authorized_keys` file when authentication at the ssh daemon.
authorizedMountedSSHKey() {
  echo "**** Enabling usage of authorized keys file ${SSH_KEYS_FILE}..."
  sudo mkdir -p ${SSH_MOUNT_PATH}
  sudo sed -i "s|^[#.*]*AuthorizedKeysFile.*|AuthorizedKeysFile .ssh/authorized_keys ${SSH_KEYS_FILE}|g" "${SSHD_CONFIG_FILE}"
}

# Disables the dns resolution in the ssh daemon to speed up logins.
disableDNSResolution() {
  echo "**** Disabling dns resolution in ssh daemon..."
  echo 'UseDNS no' >>"${SSHD_CONFIG_FILE}"
}

# Restarts the ssh daemon which reloads all configurations.
restartSshDaemon() {
  echo "**** Restarting ssh daemon..."
  sudo systemctl restart sshd.service
}

echo "**** Executing configureSSHDaemon.sh..."
disableUserPasswordLogin
authorizedMountedSSHKey
disableDNSResolution
restartSshDaemon
echo "**** Finished configureSSHDaemon.sh"
