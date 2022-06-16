#!/bin/bash
# This script is responsible for disabling the automatic updates. An update could possibly lead to a broken instance.
set -o errexit
set -o nounset
set -o pipefail

# Disables the release updates of the ubuntu system.
disableReleaseUpdates() {
  echo "**** Disabling release updates..."
  sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades
}

# Disable apt to automatically perform updates.
disablePeriodicUpdates() {
  echo "**** Disabling periodic updates..."
  cat <<EOF >/etc/apt/apt.conf.d/99_disable_periodic_update
APT::Periodic::Enable "0";
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

  # stop and kill apt-daily
  systemctl stop apt-daily.timer
  systemctl disable apt-daily.timer
  systemctl stop apt-daily.service
  systemctl daemon-reload
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    sleep 1
  done
}

# Installs the newest updates for the system.
getNewestDistUpdates() {
  echo "**** Installing newest dist updates..."
  DEBIAN_FRONTEND=noninteractive apt-get -y update
  DEBIAN_FRONTEND=noninteractive apt-get -y upgrade -o Dpkg::Options::="--force-confnew"
}

# Reboots the system after installing the system updates.
rebootAfterUpdate() {
  echo "**** Reboot system after installing dist updates..."
  reboot
}

echo "**** Executing disableAutomaticUbuntuUpdates.sh..."
disableReleaseUpdates
disablePeriodicUpdates
getNewestDistUpdates
rebootAfterUpdate
echo "**** Finished disableAutomaticUbuntuUpdates.sh"