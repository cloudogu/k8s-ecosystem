#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "**** Begin installing Longhorn"
echo "Installing Longhorn"
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.4/deploy/longhorn.yaml

echo "Waiting until Longhorn storageclass is created"
for (( i = 1; i <=19; i++ ))
    do
        echo "Request longhorn storageclass... ($i)"
        if eval kubectl get storageclass longhorn; then
            break
        fi
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