#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source .env.sh

kubectl config set-context gke_ces-operations-internal_europe-west3-a_ces-multinode
NAMESPACE="ecosystem"
./createNamespace.sh "${NAMESPACE}"
# ./installLonghorn.sh
./createCredentials.sh "${dogu_registry_username}" "${dogu_registry_password}" "${dogu_registry_url}" "${image_registry_username}" "${image_registry_password}" "${image_registry_email}"
./installLatestK8sCesSetup.sh "${NAMESPACE}"
