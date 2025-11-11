skipPreconditionValidation: false
components:
  k8s-blueprint-operator:
    version: "3.0.0-dev.1762869475"
    helmNamespace: "testing/k8s"
  k8s-ces-control:
    disabled: true
  k8s-service-discovery:
    valuesObject:
      loadBalancerService:
        internalTrafficPolicy: Cluster
        externalTrafficPolicy: Cluster
backup:
  enabled: false
monitoring:
  enabled: false