# CES Multinodes on Google Cloud (GKE)

## Notes

- get credentials: `gcloud container clusters get-credentials ces-multinode --zone europe-west3-a --project ces-operations-internal`
- Scale cluster to 0: `gcloud container clusters resize ces-multinode --num-nodes=0 --zone europe-west3-a --project ces-operations-internal`.
- This CES role has no permissions to manage all resources:
  - Clusterroles
  - Clusterrolebinding
  - roles
  - ...
- The ElasticSearch in SonarQube needs higher `virtual memory areas`.
  - This has to be adjusted directly on the node:
  - `sysctl -w vm.max_map_count=262144` must be run on every node (via SSH) for Sonar

## Storage provisioner
- Data is replicated without extra storage provisioner.

### Longhorn
- Longhorn does not start on container optimized OS:
    ```markdown
    longhorn-manager time="2023-04-27T14:20:54Z" level=error msg="Failed environment check, please make sure you have iscsiadm/open-iscsi installed on the host"
    longhorn-manager time="2023-04-27T14:20:54Z" level=fatal msg="Error starting manager: environment check failed: failed to execute: nsenter [--mount=/host/proc/1/ns/mnt --net=/host/proc/1/ns/net iscsiadm --version], output , stderr nsenter: failed to execute iscsiadm: No such file or directory\n: exit status 127"
    Stream closed EOF for longhorn-system/longhorn-manager-4m48w (wait-longhorn-admission-webhook)
    Stream closed EOF for longhorn-system/longhorn-manager-4m48w (longhorn-manager)
    ```
- Note that only one storage class is default.
- 2 CPU might be too little for Longhorn, if for example the Google-Metrics-Server runs on one node
  - outOfCpu error

## Load Balancer
- Google load balancer must be disabled by Google

