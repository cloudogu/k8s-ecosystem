#!/bin/bash
# This file is responsible to perform configuration at the start of the image build.
set -o errexit
set -o nounset
set -o pipefail

# Checks whether we currently have root access.
checkRoot() {
  echo "**** Checking root permissions..."
  if [ "$(id -u)" -ne 0 ]; then
    echo "please run as root"
    exit 1
  fi
}

# Prepares the environment.
prepareEnvironment() {
  echo "**** Preparing environment..."

  source /etc/environment
  export PATH
}

echo "**** Executing startInstallation.sh..."
checkRoot
prepareEnvironment
echo "**** Finished startInstallation.sh"
