#!/bin/bash
# This script is responsible to install and to configure fail2ban.
set -o errexit
set -o nounset
set -o pipefail

FAIL2BAN_VERSION=0.11.1-1

# Installs quest addition based on the provided builder.
installFail2Ban() {
  echo "**** Installing fail2ban..."
  DEBIAN_FRONTEND=noninteractive apt-get -y install fail2ban=${FAIL2BAN_VERSION}
}

# Sets multiple configuration values for the fail2ban client.
configureFail2Ban() {
  echo "**** Configuring fail2ban for the ssh daemon..."
  fail2ban-client set sshd addignoreip 127.0.0.1/8
  fail2ban-client set sshd maxretry 5
  fail2ban-client set sshd findtime 10m
  fail2ban-client set sshd bantime 10m
  fail2ban-client set sshd addlogpath /var/log/auth.log
}

echo "**** Executing setupFail2Ban.sh..."
installFail2Ban
configureFail2Ban
echo "**** Finished setupFail2Ban.sh"
