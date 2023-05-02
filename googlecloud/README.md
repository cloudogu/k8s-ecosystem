# CES-Multinode on a GKE-Cluster

## TODO

- install longhorn
  - without podsecuritypolicies
- create namespace
- install setup
- Done

## Notes und Mistakes 

- Get Credentials: `gcloud container clusters get-credentials ces-multinode`
- Change nodepool size: `gcloud container clusters resize ces-multinode --num-nodes=0`
- After downscaling the nodepool, etcd-client is gone: `kubectl apply -f etcd-client.yml`
- CES-Role does not have permissions to handle specific resources:
  - Clusterroles
  - Clusterrolebinding
  - Roles
  - ...
- Wenn IP-Adresse als FQDN:  
  Externe IP muss aus Node-Balancer ausgelesen werden, daher FQDN-Änderung nötig
  - `etcdctl set /config/_global/fqdn <IP>`
  - evtl. Neuinstallation von CAS oder zumindest `cas_config.sh` ausführen.
- Nginx-Ingress hat zwei LoadBalancer-Services, jeweils für HTTP und HTTPS. Ist das wirklich nötig?
- Longhorn startet auf Container-Optimized OS nicht:

  ```markdown
  longhorn-manager time="2023-04-27T14:20:54Z" level=error msg="Failed environment check, please make sure you have iscsiadm/open-iscsi installed on the host"
  longhorn-manager time="2023-04-27T14:20:54Z" level=fatal msg="Error starting manager: environment check failed: failed to execute: nsenter [--mount=/host/proc/1/ns/mnt --net=/host/proc/1/ns/net iscsiadm --version], output , stderr nsenter: failed to execute iscsiadm: No such file or directory\n: exit status 127"
  Stream closed EOF for longhorn-system/longhorn-manager-4m48w (wait-longhorn-admission-webhook)
  Stream closed EOF for longhorn-system/longhorn-manager-4m48w (longhorn-manager)
  ```
