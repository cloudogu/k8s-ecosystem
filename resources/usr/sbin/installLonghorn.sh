#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "**** Begin installing Longhorn"
echo "Installing Longhorn"
if [[ ! -e /home/ces-admin/longhorn.yaml ]]; then
    echo "Can not install Longhorn, because /home/ces-admin/longhorn.yaml does not exist. Exiting"
    exit 1
fi

kubectl apply -f /home/ces-admin/longhorn.yaml

COUNTER=20
until [  $COUNTER -lt 1 ] || kubectl get storageclass longhorn; do
    echo "Longhorn storageclass not ready yet (${COUNTER})"
    ((COUNTER-=1))
    sleep 5
done

echo "Making Longhorn the default StorageClass"
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
echo "Waiting for longhorn to start up"

for (( i = 1; i <=19; i++ )); do
    if kubectl -n longhorn-system get pods -o custom-columns=READY-true:status.containerStatuses[*].ready | grep false > /dev/null; then
        echo "Some longhorn pods are still starting (${i})"
        sleep 10
    else
        break
    fi
done

echo "**** End installing Longhorn"