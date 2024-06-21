apiVersion: v1
kind: Secret
metadata:
  name: kubelet-config
  namespace: kube-system
type: Opaque
stringData:
  config.json: |-
    {
      "auths": {
        "${image_registry_url}": {
          "auth": "${image_registry_auth}"
        }
      }
    }