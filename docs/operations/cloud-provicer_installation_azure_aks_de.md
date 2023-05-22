# CES-Multinode auf Azure AKS

## Hinweise

- Credentials bekommen: `az aks get-credentials --resource-group ces-multinode_group --name ces-multinode`
- Cluster stoppen (kann nicht auf 0 skaliert werden): `az aks stop --resource-group ces-multinode_group --name ces-multinode`
- Der Watch auf den FQDN-Change in der Service-Discovery hat erst nach einem Neustart funktioniert
    - Beim ersten Start der Service-Discovery werden anscheinend die Watches nicht gestartet.
- Der ElasticSearch in SonarQube benötigt höhere `virtual memory areas`
    - Dies muss direkt auf dem Node angepasst werden:
      ```bash
      # Einen privileged container auf dem entsprechenden Host starte
      kubectl debug node/aks-agentpool22-12519350-vmss000003 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
      
      # Dann im container den root wechseln
      chroot /host
      
      # virtual memory areas erhöhen
      sysctl -w vm.max_map_count=262144
      ```

## Storage-Provisioner
### Azure
- Daten werden ohne extra Storage-Provisioner repliziert.
- Wenn der Cluster in unterschiedlichen Availability-Zones läuft, können Volumes nicht von einem Node einer Zone in einen Node einer anderen Zone ungezogen werden
- Je nach gewählter Größe der Nodes, gibt es eine maximale Anzahl an Volumes die pro Node attached werden können. (z.B.: bei "DS2v2" sind es 8 Volumes pro Node)
    - Alternativ kan die StorageClass `azurefile-csi` als default-StorageClass verwendet werden. Diese hat keine Limitierung, da der Storage per SMB angebunden wird
        - `azurefile-csi` wird per CIFS (SMB) gemounted. Es erlaubt keine Änderung von Datei-Attributen (chmod /chown) nach dem mounten (https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/could-not-change-permissions-azure-files).

### Longhorn

- Man muss beachten, dass nur eine Storage-class default ist. Die Default-Azure-StorageClass darf nicht mehr default sein:
    - `kubectl annotate storageclass default storageclass.kubernetes.io/is-default-class="false"`


