# CES multinodes on Azure AKS

## Notes

- Getting credentials: `az aks get-credentials --resource-group ces-multinode_group --name ces-multinode`
- Stop cluster (cannot scale to 0): `az aks stop --resource-group ces-multinode_group --name ces-multinode`
- The ElasticSearch in SonarQube needs higher `virtual memory areas`.
    - This has to be adjusted directly on the node:
      ```bash
      # Start a privileged container on the corresponding host
      kubectl debug node/aks-agentpool22-12519350-vmss000003 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0

      # Then change the root in the container
      chroot /host
      
      # increase virtual memory areas
      sysctl -w vm.max_map_count=262144
      ```

## Storage-Provisioner
### Azure
- Data is replicated without extra storage provisioner.
- If the cluster is running in different Availability Zones, volumes cannot be unmounted from a node in one zone to a node in another zone.
- Depending on the selected size of the nodes, there is a maximum number of volumes that can be attached per node. (e.g.: with "DS2v2" there are 8 volumes per node).
    - Alternatively the StorageClass `azurefile-csi` can be used as default StorageClass. This has no limitation, because the storage is connected via SMB
        - `azurefile-csi` is mounted via CIFS (SMB). It does not allow changing file attributes (chmod /chown) after mounting (https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/could-not-change-permissions-azure-files).
### Longhorn

- Note that only one storage class is default. The default Azure StorageClass must not be default anymore:
    - `kubectl annotate storageclass default storageclass.kubernetes.io/is-default-class="false"`

## Air-gapped environment without external load balancer service IP address

In air-gapped clusters, the cloud provider may not be able to assign an external IP address.
With the annotation `"service.beta.kubernetes.io/azure-load-balancer-internal": "true"` on the load balancer service, you can configure Azure to assign an external IP address from the internal network to the service.

In the [Setup-Config](https://github.com/cloudogu/k8s-ces-setup/blob/develop/docs/operations/configuration_guide_en.md#resource_patches) this can be configured as follows:

```yaml
...
resource_patches:
  - phase: loadbalancer
    resource:
      apiVersion: v1
      kind: Service
      name: ces-loadbalancer
    patches:
      - op: add
        path: /metadata/annotations
        value:
          service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```
