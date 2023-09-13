#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This file runs on the host (compared to from within a VM) and executes finishing touches. Please note that this
# script is executed after every vagrant up, so repeating calls must not fail.

export ETC_HOSTS=/etc/hosts

function updateKubectlAccess() {
  echo "Setting up k3ces.local cluster access ..."
  vagrantSetupCluster="$(cat <<EOF
cd /vagrant \
&& sudo cp /etc/rancher/k3s/k3s.yaml k3s.yaml
EOF
  )"

  vagrant ssh -- -t "${vagrantSetupCluster}"
  sed 's/default/k3ces.local/g' < k3s.yaml > ~/.kube/k3ces.local || true

  export KUBECONFIG=~/.kube/k3ces.local
  kubectl config use k3ces.local
  rm -f k3s.yaml
  echo "The export of the \"export KUBECONFIG=~/.kube/config:~/.kube/k3ces.local\" should be added to the startup enviroment (e.g.: bashrc, zshrc, profile)."
}

function detectFqdnInEtcHosts() {
  local fqdn="${1}"
  local ip="${2}"
  echo "Checking if FQDN ${fqdn} was configured in /etc/hosts..."

  if ! grep "${fqdn}" "${ETC_HOSTS}" > /dev/null ; then
    echo "INFO: Do not forget to add an FQDN alias to your /etc/hosts:
  sudo sh -c 'echo \"${ip}     ${fqdn}\" >> /etc/hosts'"
  fi
}

function runSetup() {
  local fqdn="${1}"
  local ip="${2}"
  updateKubectlAccess
  detectFqdnInEtcHosts "${fqdn}" "${ip}"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runSetup "$@"
fi
