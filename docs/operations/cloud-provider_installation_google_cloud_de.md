# CES-Multinode auf Google Cloud (GKE)

## Hinweise

- Credentials bekommen: `gcloud container clusters get-credentials ces-multinode --zone europe-west3-a --project ces-operations-internal`
- Cluster auf 0 skalieren: `gcloud container clusters resize ces-multinode --num-nodes=0 --zone europe-west3-a --project ces-operations-internal`
- Dies CES-Role hat keine Berechtigungen um die alle Ressourcen zu verwalten:
    - Clusterroles
    - Clusterrolebinding
    - Roles
    - ...
- Der ElasticSearch in SonarQube benötigt höhere `virtual memory areas`
    - Dies muss direkt auf dem Node angepasst werden:
    - `sysctl -w vm.max_map_count=262144` muss auf jeden Node (per SSH) für Sonar ausgeführt werden

## Storage-Provisioner
- Daten werden ohne extra Storage-Provisioner repliziert.

### Longhorn
- Longhorn startet auf Container-Optimized OS nicht:
    ```markdown
    longhorn-manager time="2023-04-27T14:20:54Z" level=error msg="Failed environment check, please make sure you have iscsiadm/open-iscsi installed on the host"
    longhorn-manager time="2023-04-27T14:20:54Z" level=fatal msg="Error starting manager: environment check failed: failed to execute: nsenter [--mount=/host/proc/1/ns/mnt --net=/host/proc/1/ns/net iscsiadm --version], output , stderr nsenter: failed to execute iscsiadm: No such file or directory\n: exit status 127"
    Stream closed EOF for longhorn-system/longhorn-manager-4m48w (wait-longhorn-admission-webhook)
    Stream closed EOF for longhorn-system/longhorn-manager-4m48w (longhorn-manager)
    ```
- Man muss beachten, dass nur eine Storage-class default ist.
- 2 CPU könnten schon zu wenig für Longhorn sein, wenn zum Beispiel der Google-Metrics-Server auf einem Node läuft
    - outOfCpu error


## Load-Balancer
- Google-Loadbalancer muss von Google deaktiviert werden

