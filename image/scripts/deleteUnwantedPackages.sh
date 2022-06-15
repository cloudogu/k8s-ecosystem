#!/bin/bash
# This script is responsible to delete unwanted or unused packages to reduce the size of the final image.
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
  DEBIAN_FRONTEND=noninteractive apt -y purge ppp pppconfig pppoeconf
  # Delete oddities
  DEBIAN_FRONTEND=noninteractive apt -y purge popularity-contest
  # Delete X11 libraries
  DEBIAN_FRONTEND=noninteractive apt -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6
}

# Starts the autoremove and clean procedures of apt.
aptAutoClean() {
  echo "**** Automatically remove unused packages and dependencies using apt..."
  DEBIAN_FRONTEND=noninteractive apt -y autoremove
  DEBIAN_FRONTEND=noninteractive apt -y clean
}

# Manually deletes obsolete or unused files from the system.
manuallyRemoveUnusedFiles() {
  echo "**** Manually removing obsolete/unused files..."

  # remove temporary install resources
  rm -f VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?
  rm -rf /home/ces-admin/resources /home/ces-admin/install/
}

echo "**** Executing deleteUnwantedPackages.sh..."
manuallyRemoveUnusedFiles
purgeUnwantedPackages
aptAutoClean
echo "**** Finished deleteUnwantedPackages.sh"
