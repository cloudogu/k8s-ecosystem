# Generate kubeconfig for shoot cluster

```bash
export NAMESPACE=garden-my-namespace
export SHOOT_NAME=my-shoot
export KUBECONFIG=<kubeconfig for garden cluster>  # can be set using "gardenctl target --garden <landscape>"
kubectl create \
-f <(printf '{"spec":{"expirationSeconds":600}}') \
--raw /apis/core.gardener.cloud/v1beta1/namespaces/${NAMESPACE}/shoots/${SHOOT_NAME}/adminkubeconfig | \
jq -r ".status.kubeconfig" | \
base64 -d > shootconfig.yaml
```
