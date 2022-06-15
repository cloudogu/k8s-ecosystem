#!/bin/bash
# This file is responsible to perform configuration for the linux grub bootloader.
set -o errexit
set -o nounset
set -o pipefail

# Sets the grub timeout to zero seconds which speeds up the login process as the CES does not need to be selected.
setGrubTimeoutToZero() {
  echo "**** Setting grub timeout to zero..."
  cat <<EOF >/etc/default/grub
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg.

GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2>/dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX="debian-installer=en_US"
EOF
}

# Updates the grub so that the latest changes are effective after reboot.
updateGrub() {
  echo "**** Updating grub..."
  update-grub
}

echo "**** Executing configureGrub.sh..."
setGrubTimeoutToZero
updateGrub
echo "**** Finished configureGrub.sh"
