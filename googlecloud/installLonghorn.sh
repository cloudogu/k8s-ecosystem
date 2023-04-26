#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

kubectl apply -f https://raw.githubusercontent.com/cloudogu/k8s-longhorn/v1.4.1-1/manifests/longhorn.yaml

COUNTER=0
until [ $COUNTER -gt 50 ] || kubectl get storageclass longhorn >> /dev/null 2>&1; do
    sleepInterval=5
    echo "Longhorn storageclass not ready yet ($((COUNTER * sleepInterval))s)"
    ((COUNTER+=1))
    sleep $sleepInterval
done

if ! kubectl get storageclass longhorn >> /dev/null; then
    echo "Longhorn storage class is still not ready! Exiting"
    exit 1
fi

echo "Making Longhorn the default StorageClass"
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
echo "Waiting for longhorn to start up"

for (( i = 0; i <=50; i++ )); do
    sleepInterval=10
    if kubectl -n longhorn-system get pods -o custom-columns=READY-true:status.containerStatuses[*].ready | grep false > /dev/null; then
        echo "Some longhorn pods are still starting ($((i * sleepInterval))s)"
        sleep $sleepInterval
    else
        echo "Longhorn has started"
        break
    fi
done

echo "**** End installing Longhorn"