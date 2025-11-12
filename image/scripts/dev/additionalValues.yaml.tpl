skipPreconditionValidation: false
components:
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