#!/bin/bash
# This script is responsible to perform several operations to optimize the size of the final image.
set -o errexit
set -o nounset
set -o pipefail

# Purges all unwanted packages from the system.
purgeUnwantedPackages() {
  echo "**** Purging unwanted packages..."

  # remove unwanted/unused linux headers
  DEBIAN_FRONTEND=noninteractive dpkg --list |
    awk '{ print $2 }' |
    grep 'linux-headers' |
    xargs apt-get -y purge

  # Delete obsolete networking
  DEBIAN_FRONTEND=noninteractive apt-get -y purge ppp pppconfig pppoeconf
  # Delete oddities
  DEBIAN_FRONTEND=noninteractive apt-get -y purge popularity-contest
  # Delete X11 libraries
  DEBIAN_FRONTEND=noninteractive apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6
}

# Starts the autoremove and clean procedures of apt.
aptAutoClean() {
  echo "**** Automatically remove unused packages and dependencies using apt..."
  DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
  DEBIAN_FRONTEND=noninteractive apt-get -y clean
}

# Deletes obsolete or unused files from the system.
removeUnusedFiles() {
  echo "**** Removing obsolete/unused files..."

  # remove temporary install resources
  rm -f VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?
  rm -rf /home/ces-admin/resources /home/ces-admin/install/
}

# Disables the swap partition until the machine reboots. This reduces the final image size as the swap partition does not need to be included.
disableSwapUntilReboot() {
  echo "**** Disabling swap until reboot..."

  local swapUUID
  swapUUID=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
  if [ "x${swapUUID}" != "x" ]; then
    # Whiteout the swap partition to reduce box size
    # Swap is disabled till reboot
    local swapPart
    swapPart=$(readlink -f "/dev/disk/by-uuid/${swapUUID}")
    /sbin/swapoff "${swapPart}"
    dd if=/dev/zero of="${swapPart}" bs=1M || echo "dd exit code $? is suppressed"
    /sbin/mkswap -U "${swapUUID}" "${swapPart}"
  fi
}

# Write zeroes to any free spaces to reduce the size of the final image.
zeroOutFreeSpace() {
  echo "**** Overwriting all unused space with zeros..."
  dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
  rm -f /EMPTY

  # Sync to ensure that the delete completes before this moves on.
  sync
  sync
  sync
}

echo "**** Executing optimizeImageSize.sh..."
removeUnusedFiles
purgeUnwantedPackages
aptAutoClean
disableSwapUntilReboot
zeroOutFreeSpace
echo "**** Finished optimizeImageSize.sh"
