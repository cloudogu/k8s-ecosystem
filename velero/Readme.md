# Velero + Longhorn Backup&Restore

## MinIO Configuration

Setup local MinIO
```shell
docker run -d --name minio \
-p 9000:9000 -p 9090:9090 \
-e "MINIO_ROOT_USER=MINIOADMIN" \
-e "MINIO_ROOT_PASSWORD=MINIOADMINPW" \
quay.io/minio/minio \
server /data --console-address ":9090"
```

Open MinIO Administration on http://localhost:9000:
- Create Bucket _longhorn_
- Create Bucket _velero_
- Create Access Key
  - KeyID: `longhorn-test-key`
  - Secret Access Key: `longhorn-test-secret-key`

## Enable Volume Encryption

```shell
k apply -f longhorn/
kubectl patch storageclass longhorn-crypt -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

## Longhorn Configuration

Create MinIO Secret for Longhorn:
```shell
k -n longhorn-system apply -f minio-secret.yaml
```

Port-forward Longhorn UI:
```shell
k -n longhorn-system port-forward service/longhorn-frontend 8000:8000
```

Create Backup Target and Backup Target Credential Secret in Longhorn UI
- Backup Target: s3://longhorn@dummyregion/
- Backup Target Credential Secret: minio-secret

## Snapshot controller and CSI Snapshot CRDs

Install snapshot controller and CSI Snapshot CRDs (K3s does not have them by default):
```shell
k -n kube-system create -k snapshot-controller/5.0/crd
k -n kube-system create -k snapshot-controller/5.0/snapshot-controller
```

Apply default VolumeSnapshotClass:
```shell
k apply -f default-volumesnapshotclass.yaml
```

## Velero Configuration

Install Velero:
```shell
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts

helm install velero \
--namespace=velero \
--set-file credentials.secretContents.cloud=credentials-velero \
--set configuration.provider=aws \
--set configuration.backupStorageLocation.name=default \
--set configuration.backupStorageLocation.bucket=velero \
--set configuration.backupStorageLocation.config.region=minio-default \
--set configuration.backupStorageLocation.config.s3ForcePathStyle=true \
--set configuration.backupStorageLocation.config.s3Url=http://192.168.56.1:9000 \
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

## Test Backup and Restore

Install test application:
```shell
k apply -f examples/csi-test/pod-pvc.yaml
```

Write test data:
```shell
kubectl -n csi-app exec -ti csi-nginx -- bash -c 'echo -n "FOOBARBAZ" >> /mnt/longhorndisk/foobar'
```

Do a backup:
```shell
./velero backup create csi-b1 --include-namespaces csi-app --wait
```

Simulate disaster:
```shell
k delete ns csi-app
```

Apply backup:
```shell
./velero restore create --from-backup csi-b1 --wait
```