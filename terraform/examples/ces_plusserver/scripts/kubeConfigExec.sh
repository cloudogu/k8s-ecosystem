#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

gardenerKubeConfig=$1
shootName=$2
namespace=$3
clusterIdentity=$4

./bin/gardenctl config set-garden "${clusterIdentity}" --kubeconfig "${gardenerKubeConfig}" > test.log 2>&1

# This var usually contains following entry when invoked by the terraform provisioner exec:
# {"kind":"ExecCredential","apiVersion":"client.authentication.k8s.io/v1beta1","spec":{"interactive":true}}
# With this var gardenlogin can't create a new config. Even though the help menu from gardenlogin states that this variable is required.
unset KUBERNETES_EXEC_INFO
./bin/gardenlogin get-client-certificate --name "${shootName}" --namespace "${namespace}" --garden-cluster-identity "${clusterIdentity}"