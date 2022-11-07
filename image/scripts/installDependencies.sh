#!/bin/bash
# This script is responsible to install all dependencies used in the process of building and operating the image.
set -o errexit
set -o nounset
set -o pipefail

# Installs required packages with apt.
installAptDependencies() {
  echo "**** Install dependencies..."
  DEBIAN_FRONTEND=noninteractive apt-get -y update
  DEBIAN_FRONTEND=noninteractive apt-get install -y nfs-common jq
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

installNonAptDependencies() {
  installYQ
}

installYQ() {
  local yq="/usr/local/bin/yq"
  local yq_version="v4.28.1"
  local yq_url="https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64"
  local yq_sha256sum="818cb646d68c016b840d8db2f614553e488121d6a41aa0619fd16f17ed3a83d8"

  wget -qO "${yq}" "${yq_url}"
  echo "${yq_sha256sum} ${yq}" | sha256sum -c
  chmod a+x "${yq}"
}

echo "**** Executing installDependencies.sh..."
installAptDependencies
installNonAptDependencies
installOptionalDependencies
echo "**** Finished installDependencies.sh"
