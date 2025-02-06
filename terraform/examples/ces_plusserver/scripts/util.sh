#!/bin/bash

set -o nounset

caCertFile="./cacert"
certFile="./cert"
keyFile="./key"

# extractKubeConfig decodes authentication data from the given kubeconfig and writes them to files cacert, cert and key
# in order to use them with curl. Remove the auth files after usage with removeAuthFiles.
extractKubeConfig() {
  grep -A 1 certificate-authority-data "$1" | head -1 | sed 's/certificate-authority-data://g' | awk '{$1=$1};1' | base64 -d > "${caCertFile}"
  grep client-certificate-data "$1" | sed 's/client-certificate-data://g' | awk '{$1=$1};1' | base64 -d > "${certFile}"
  grep client-key-data "$1" | sed 's/client-key-data://g' | awk '{$1=$1};1' | base64 -d > "${keyFile}"

  grep server "$1" | head -1 | sed 's/server://g' | awk '{$1=$1};1'
}

removeAuthFiles() {
  rm -f "${caCertFile}" "${certFile}" "${keyFile}"
}

