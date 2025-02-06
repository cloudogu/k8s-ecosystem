#!/bin/bash

set -o nounset
set -o pipefail

clusterName="$1"
projectID="$2"
apiURLProjects="api.${clusterName}.${projectID}.projects.prod.gardener.get-cloud.io"

for i in {1..60}; do
    if nslookup "${apiURLProjects}"; then
    echo "Successfully checked DNS"
    break
  fi
  echo "Waiting for DNS to propagate..."
  sleep 5
done

code=""
until [[ "${code}" == "401" ]]; do
  code=$(curl -k -s -o /dev/null -w "%{http_code}" --head --fail "https://${apiURLProjects}")
  echo "Waiting for api ${apiURLProjects} to be up..."
  sleep 10
done

sleep 30
