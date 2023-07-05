# CES multinode on Plusserver (PSKE)

## Hints
- `kubeconfig` can be downloaded here: https://dashboard.prod.gardener.get-cloud.io/namespace/<your-garden>/shoots/.
- Example usage of config: `export KUBECONFIG=${KUBECONFIG}:~/.kube/kubeconfig-<your-garden-context>.yaml`

## Storage provisioner

- Data is replicated without extra storage provisioner.
- Hibernate works **without** Longhorn. Data is preserved with new nodes.
- **Caution**: With Longhorn, all data is lost when scaling cluster to 0 nodes.

### Longhorn

- Note that only one storage class is default.
- 2 CPU could be too little for Longhorn.

## Load balancer

- If you delete the `ecosystem` namespace and run a setup again, it can happen that the LoadBalancer assigns new IPs. In this case it is necessary to run the script: `syncFQDN.sh` again.

## Scheduling

- The `kubelet` or `gardenlet` has two strategies for scheduling: `balanced` (dafault) and `bin-packing`.
- Because dogus do not yet have resource request and limits, `balanced` does not seem to perform 100% balanced distribution.
- During setup, it may happen that pods are evicted and restart on other nodes.
- Evicted pods can be deleted.

## Sonar

- `vm.max_map_count` problem does **not** occur