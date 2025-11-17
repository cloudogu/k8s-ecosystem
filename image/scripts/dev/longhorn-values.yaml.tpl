defaultSettings:
  logLevel: Info
  nodeDownPodDeletionPolicy: delete-both-statefulset-and-deployment-pod
  deletingConfirmationFlag: true
  storageOverProvisioningPercentage: "1000"
persistence:
  defaultClassReplicaCount: DEFAULTCLASSREPLICACOUNT
csi:
  attacherReplicaCount: DEFAULTCLASSREPLICACOUNT
  provisionerReplicaCount: DEFAULTCLASSREPLICACOUNT
  resizerReplicaCount: DEFAULTCLASSREPLICACOUNT
  snapshotterReplicaCount: DEFAULTCLASSREPLICACOUNT