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
echo "**** End installing Longhorn"