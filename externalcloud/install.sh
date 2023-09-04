#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source .env.sh

kubectl config set-context "${kube_context}"
namespace="ecosystem"
./createNamespace.sh "${namespace}"
#./installLonghorn.sh
./installLatestK8sCesSetup.sh "${namespace}" "${helm_repository_namespace}" "${dogu_registry_username}" "${dogu_registry_password}" "${dogu_registry_url}" "${image_registry_username}" "${image_registry_password}" "${image_registry_url}" "${helm_registry_username}" "${helm_registry_password}" "${helm_registry_host}" "${helm_registry_schema}" "${helm_registry_plain_http}"