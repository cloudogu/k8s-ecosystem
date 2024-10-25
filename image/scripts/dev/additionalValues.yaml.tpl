container_registry_secrets:
  - url: CONTAINER_REGISTRY_SECRET_URL
    username: "CONTAINER_REGISTRY_SECRET_USERNAME"
    password: "CONTAINER_REGISTRY_SECRET_PASSWORD" # Base64 encoded password
dogu_registry_secret:
  url: DOGU_REGISTRY_SECRET_URL
  urlschema: "DOGU_REGISTRY_SECRET_URL_SCHEMA"
  username: "DOGU_REGISTRY_SECRET_USERNAME"
  password: "DOGU_REGISTRY_SECRET_PASSWORD" # Base64 encoded password
helm_registry_secret:
  host: HELM_REGISTRY_SECRET_HOST
  schema: HELM_REGISTRY_SECRET_SCHEMA
  plainHttp: "HELM_REGISTRY_SECRET_PLAIN_HTTP"
  username: "HELM_REGISTRY_SECRET_USERNAME"
  password: "HELM_REGISTRY_SECRET_PASSWORD" # Base64 encoded password
components:
  k8s-longhorn:
    version: latest
    helmRepositoryNamespace: k8s
    deployNamespace: longhorn-system
    valuesYamlOverwrite: |
      longhorn:
        defaultSettings:
          storageOverProvisioningPercentage: 1000
        persistence:
          defaultClassReplicaCount: DEFAULTCLASSREPLICACOUNT
        csi:
          attacherReplicaCount: DEFAULTCLASSREPLICACOUNT
          provisionerReplicaCount: DEFAULTCLASSREPLICACOUNT
          resizerReplicaCount: DEFAULTCLASSREPLICACOUNT
          snapshotterReplicaCount: DEFAULTCLASSREPLICACOUNT
        longhornUI:
          # Scale this up, if UI is needed
          replicas: 0