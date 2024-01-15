#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This file runs on the host (compared to from within a VM) and executes finishing touches. Please note that this
# script is executed after every vagrant up, so repeating calls must not fail.

export ETC_HOSTS=/etc/hosts

function updateKubectlAccess() {
  local port="${1}"
  local ctxName="${2}"
  echo "Setting up $ctxName cluster access ..."
  vagrantSetupCluster="$(cat <<EOF
cd /vagrant \
&& sudo cp /etc/rancher/k3s/k3s.yaml k3s.yaml
EOF
  )"

  vagrant ssh -- -t "${vagrantSetupCluster}"
  # create kubeconfig if it does not exist and give the user write permissions
  # also avoid the following k3s warning: "Kubernetes configuration file is world/group-readable"
  touch "${HOME}/.kube/$ctxName"
  chmod 600 "${HOME}/.kube/$ctxName"
  sed "s/default/$ctxName/g" < k3s.yaml > "${HOME}/.kube/$ctxName"
  sed "s/127.0.0.1:6443/127.0.0.1:$port/g" -i "${HOME}/.kube/$ctxName"
  export KUBECONFIG="${HOME}/.kube/$ctxName"
  kubectl config use "$ctxName"
  rm -f k3s.yaml
  echo "The export of the \"export KUBECONFIG=~/.kube/config:~/.kube/$ctxName\" should be added to the startup enviroment (e.g.: bashrc, zshrc, profile)."
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
    echo "fqdn: ${1}"
    echo "ip: ${2}"
    echo "port: ${3}"
    echo "ctxName: ${4}"

  local fqdn="${1}"
  local ip="${2}"
  local port="${3:-6443}"
  local ctxName="${4:-k3ces.local}"
  updateKubectlAccess "${port}" "${ctxName}"
  detectFqdnInEtcHosts "${fqdn}" "${ip}"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runSetup "$@"
fi
