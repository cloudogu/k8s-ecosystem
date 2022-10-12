#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

registryURL=$1
imageList="longhornio/longhorn-manager:v1.3.1 longhornio/longhorn-ui:v1.3.1 longhornio/csi-attacher:v3.4.0 longhornio/csi-provisioner:v2.1.2 longhornio/csi-resizer:v1.2.0 longhornio/csi-snapshotter:v3.0.3 longhornio/csi-node-driver-registrar:v2.5.0 longhornio/longhorn-instance-manager:v1_20220808 longhornio/longhorn-engine:v1.3.1"

echo "Docker login ${registryURL}"
docker login "${registryURL}"
for image in ${imageList}; do
  docker pull "${image}"
  taggedImage="${registryURL}/${image}"
  docker tag "${image}" "${taggedImage}"
  docker push "${taggedImage}"
done
