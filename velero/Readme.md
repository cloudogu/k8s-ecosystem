# Velero

## Backups with CSI Snapshots of Longhorn Volumes

Install snapshot controller and CSI Snapshot CRDs (K3s does not have them by default):
```shell
k -n kube-system create -k snapshot-controller/5.0/crd
k -n kube-system create -k snapshot-controller/5.0/snapshot-controller
```
```shell
k -n kube-system create -k snapshot-controller/6.2/crd
k -n kube-system create -k snapshot-controller/6.2/snapshot-controller
```

Install Velero:
```shell
helm install velero \
--namespace=velero \
--create-namespace \
--set-file credentials.secretContents.cloud=credentials-velero \
--set configuration.provider=aws \
--set configuration.backupStorageLocation.name=default \
--set configuration.backupStorageLocation.bucket=velero \
--set configuration.backupStorageLocation.config.region=minio-default \
--set configuration.backupStorageLocation.config.s3ForcePathStyle=true \
--set configuration.backupStorageLocation.config.s3Url=http://minio-default.velero.svc.cluster.local:9000 \
--set configuration.backupStorageLocation.config.publicUrl=http://localhost:9000 \
--set snapshotsEnabled=true \
--set configuration.volumeSnapshotLocation.name=default \
--set configuration.volumeSnapshotLocation.config.region=minio-default \
--set "initContainers[0].name=velero-plugin-for-aws" \
--set "initContainers[0].image=velero/velero-plugin-for-aws:v1.6.0" \
--set "initContainers[0].volumeMounts[0].mountPath=/target" \
--set "initContainers[0].volumeMounts[0].name=plugins" \
--set configuration.features=EnableCSI \
--set "initContainers[1].name=velero-plugin-for-csi" \
--set "initContainers[1].image=velero/velero-plugin-for-csi:v0.4.0" \
--set "initContainers[1].volumeMounts[0].mountPath=/target" \
--set "initContainers[1].volumeMounts[0].name=plugins" \
vmware-tanzu/velero
```

Install MinIO:
```shell
k -n velero apply -f examples/minio/00-minio-deployment.yaml
```

Apply default VolumeSnapshotClass: 
```shell
k apply -f default-volumesnapshotclass.yaml
```

Install test application:
```shell
k apply -f examples/csi-test/pod-pvc.yaml
```

Write test data:
```shell
k -n csi-app exec -ti csi-nginx bash
# while true; do echo -n "FOOBARBAZ " >> /mnt/longhorndisk/foobar; done 
^C
```

Do a backup:
```shell
./velero backup create csi-b2 --include-namespaces csi-app --wait
```

Simulate disaster:
```shell
k delete ns csi-app
```

Apply backup:
```shell
./velero restore create --from-backup csi-b2 --wait
```