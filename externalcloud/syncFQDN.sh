#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

kubectl rollout restart deployment k8s-service-discovery-controller-manager -n ecosystem
kubectl rollout status deployment k8s-service-discovery-controller-manager -n ecosystem

etcdClientPod="$(kubectl -n ecosystem get pod | grep etcd-client | awk '{print $1}')"
fqdn=$(kubectl get -n ecosystem svc nginx-ingress-exposed-443 -o json | jq -r '.status.loadBalancer.ingress[0].ip')
kubectl exec -n ecosystem -it "${etcdClientPod}" -- etcdctl set config/_global/fqdn "${fqdn}"
sleep 15

kubectl -n ecosystem get dogus | grep -v AGE | awk '{print $1}' | xargs kubectl rollout restart deployment -n ecosystem