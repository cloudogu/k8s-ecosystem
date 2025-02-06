# How to set up

- Template vars
- Get gardener kubeconfig from PSKE and save as `gardener_kubeconfig.yaml`
- `terraform apply -var-file=secretVars.tfvars -var-file=vars.tfvars -target=null_resource.getShootKubeConfig`
- Wait a minute
- `terraform apply -var-file=secretVars.tfvars -var-file=vars.tfvars -target=module.ces`

# Commands for scripts

Grep token from gardener config, remove attribute "token: >-" with tail and strip whitespaces with awk:
- `grep -A 1 token gardener_kubeconfig.yaml | tail -1 | awk '{$1=$1};1'`

Grep certificate from gardener config, remove attribute "certificate-authority-data: >-" with tail and strip whitespaces with awk, decode it and write it to a file:
- `grep -A 1 certificate-authority-data gardener_kubeconfig.yaml | tail -1 | awk '{$1=$1};1' | base64 --decode > cert`

Grep cluster ip:
- `grep server gardener_kubeconfig.yaml | sed 's/server://g' | awk '{$1=$1};1'`

Create kubeconfig with curl:

- `curl ${server}/apis/core.gardener.cloud/v1beta1/namespaces/${namespace}/shoots/${shoot}/adminkubeconfig -H "Authorization: Bearer ${token}" --cacert ${certFile} -X POST -d '{"spec":{"expirationSeconds":600}}' -H "Content-Type: application/json"`


# Issues

## No cluster terraform provider available
- Kubeconfig for shoot cluster is only known during apply
  - Solution: No Solution -> 2 phase terraform apply with -target=null_resource.getShootKubeConfig.sh first

## IPs are not reservable with terraform resources
- IPs can't be reserved before cluster creation via terraform provider
  - Solution: Create loadbalancer before EcoSystem and reuse it.
    - Needs newest setup version compatible with previously created load balancer service

## Namespace have to be created in order to reserve an ip with a loadbalancer
- Namespace can't be created with terraform resource because the terraform destroy command will be stuck (EcoSystem finalizers)
  - Solution: Create namespace with null_resource script to avoid containing it in state.

## General cluster cleanup does not work in PSKE
- If finalizer are in the cluster the removal of the cluster stucks until a force policy will be used (1-2 hours)
  - Solution: ? ignore

## Network policies and cilium cni
- Dogus are not available with current network policies (cilium)
- Dogus needs permission to access nginx-ingress via policies (cilium)
- Test calico:
  - Works

## Jenkins/Service-Discovery Bug
- Jenkins does not start, because ingress was created with port 50000 instead of 8080
- `ces-services` annotations contains both ports on `/jenkins`. The last port will be mapped to ingress (Service-Disc bug?)


# TODO

## Releasing reserved ip
- Loadbalancer should reserve IP via annotation.
- On destroy the loadbalancer have to be patched with reserve: false to release the ip

## Wait for shoot api

## Jenkins Bug
- Analyse (s.o.)

