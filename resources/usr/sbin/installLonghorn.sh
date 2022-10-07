#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

username=${1}

echo "**** Begin installing Longhorn"
echo "Installing Longhorn"
if [[ ! -e /home/${username}/longhorn.yaml ]]; then
    echo "Can not install Longhorn, because /home/${username}/longhorn.yaml does not exist. Exiting"
    exit 1
fi

kubectl apply -f /home/"${username}"/longhorn.yaml

COUNTER=0
until [ $COUNTER -gt 20 ] || kubectl get storageclass longhorn >> /dev/null 2>&1; do
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

for (( i = 0; i <=19; i++ )); do
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