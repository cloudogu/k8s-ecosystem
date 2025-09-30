skipPreconditionValidation: false
components:
  k8s-blueprint-operator-crd:
    version: "1.3.0-dev.1757922891"
    helmNamespace: "testing/k8s"
  k8s-blueprint-operator:
    version: "2.8.0-dev.1758811397"
    helmNamespace: "testing/k8s"
    valuesObject:
      healthConfig:
        components:
          required:
            - name: k8s-dogu-operator
            - name: k8s-service-discovery
  k8s-service-discovery:
    valuesObject:
      loadBalancerService:
        internalTrafficPolicy: Cluster
        externalTrafficPolicy: Cluster
backup:
  enabled: false
monitoring:
  enabled: false