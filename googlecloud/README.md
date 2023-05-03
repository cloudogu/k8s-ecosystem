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
- ETCD-Client sollte als Deployment und nicht nur als POD deployed werden.

- Daten werden ohne extra Storage-Provisioner repliziert.

- `sysctl -w vm.max_map_count=262144` muss auf jeden Node für Sonar ausgeführt werden

- Longhorn startet auf Container-Optimized OS nicht:
```markdown
longhorn-manager time="2023-04-27T14:20:54Z" level=error msg="Failed environment check, please make sure you have iscsiadm/open-iscsi installed on the host"
longhorn-manager time="2023-04-27T14:20:54Z" level=fatal msg="Error starting manager: environment check failed: failed to execute: nsenter [--mount=/host/proc/1/ns/mnt --net=/host/proc/1/ns/net iscsiadm --version], output , stderr nsenter: failed to execute iscsiadm: No such file or directory\n: exit status 127"
Stream closed EOF for longhorn-system/longhorn-manager-4m48w (wait-longhorn-admission-webhook)
Stream closed EOF for longhorn-system/longhorn-manager-4m48w (longhorn-manager)
```

- Man muss beachten, dass nur eine Storage-class default ist.


## Thematik Load-Balancer und IP


  Externe IP muss aus Node-Balancer ausgelesen werden, daher FQDN-Änderung nötig
  - `etcdctl set /config/_global/fqdn <IP>`
  - evtl. Neuinstallation von CAS oder zumindest `cas_config.sh` ausführen.
- Nginx-Ingress hat zwei LoadBalancer-Services, jeweils für HTTP und HTTPS. Ist das wirklich nötig?

- Google-Loadbalancer muss von Google deaktiviert werden
  - Generell: Wieso hat nginx-ingress nicht einen Service für HTTP und HTTPS?

Wenn IP-Adresse als FQDN:
- Die FQDN kann beim Setup anfangs nicht korrekt angegeben werden
  - Es ist unklar, ob man ermitteln kann, welche IP dem Service Loadbalancer zugeordnet wird.
  - Externe IP muss aus Node-Balancer ausgelesen werden, daher FQDN-Änderung nötig
  - `etcdctl set /config/_global/fqdn <IP>`
  - evtl. Neuinstallation von CAS oder zumindest `cas_config.sh` ausführen.
- Nginx-Ingress hat zwei LoadBalancer-Services, jeweils für HTTP und HTTPS. Ist das wirklich nötig?

- FQDN nachträglich geändert und Dogus neu gestartet: To many redirects bei Aufruf `/nexus`
  - Anschließend muss das Zertifikat neu generiert werden -> TODO Story erstellen automatisiert.
  - Zertifikatsgenerierung über API dauert sehr lang oder freezed -> TODO Analyse

- Postgres-Container hat eine andere Routing-Tabelle. Das Dogu verarbeitet nur die genaue. 0.0.0.0 wir ignoriert. 
  - Muss im Dogu behoben werden. TODO Story

