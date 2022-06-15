#!/bin/bash
# This script is responsible to install all dependencies used in the process of building and operating the image.

set -o errexit
set -o nounset
set -o pipefail

# Installs required packages with apt.
installAptDependencies() {
  echo "**** Install dependencies..."
  DEBIAN_FRONTEND=noninteractive apt -y update
  DEBIAN_FRONTEND=noninteractive apt install -y nfs-common jq docker.io
}

# Installs optional dependency linux-image-extra for the given kernel. This package seems to be unavailable in some environments.
installOptionalDependencies() {
  echo "**** Install optional dependencies..."
  local imageExtraPkg
  imageExtraPkg=linux-image-extra-"$(uname -r)"
  if apt-cache search "${imageExtraPkg}" | grep "${imageExtraPkg}" &>/dev/null; then
    echo "installing optional package ${imageExtraPkg}"
    DEBIAN_FRONTEND=noninteractive apt-get -y install "${imageExtraPkg}"
  else
    echo "WARNING: could not find optional package ${imageExtraPkg}"
  fi
}

echo "**** Executing installDependencies.sh..."
installAptDependencies
installOptionalDependencies
echo "**** Finished installDependencies.sh"
