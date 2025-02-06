#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

gardenCtlSource="$1"
gardenCtlSHA256="$2"
gardenLoginSource="$3"
gardenLoginSHA256="$4"

binPath="./bin"
mkdir -p "${binPath}"

gardenCtlPath="${binPath}/gardenctl"
wget -q -O "${gardenCtlPath}" "${gardenCtlSource}"
echo "${gardenCtlSHA256} ${gardenCtlPath}" | sha256sum --check

gardenLoginPath="${binPath}/gardenlogin"
wget -q -O "${gardenLoginPath}" "${gardenLoginSource}"
echo "${gardenLoginSHA256} ${gardenLoginPath}" | sha256sum --check

chmod +x "${gardenCtlPath}" "${gardenLoginPath}"




