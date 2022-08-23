#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

until [[ $(systemctl is-active k3s-conf) == "inactive" ]]; do
  echo "k3s-conf service is still active, waiting..."
  sleep 2
done