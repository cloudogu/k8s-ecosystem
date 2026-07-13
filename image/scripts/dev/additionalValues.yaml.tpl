skipPreconditionValidation: false
components:
  k8s-ces-control:
    disabled: true
  k8s-service-discovery:
    valuesObject:
      loadBalancerService:
        internalTrafficPolicy: Cluster
        externalTrafficPolicy: Cluster
      exposition:
        exposePorts: true
        discoverServices: true
        discoverExpositionCR: true
  lop-idp:
    valuesObject:
      ldap:
        secrets:
          initialAdminPasswordSecretRef:
            create: false
            name: initial-admin-password
            passwordKey: admin-password
      cas:
        configuration:
          normal:
            allow_local_urls: "true"
  k8s-exposition-crd:
    version: 1.0.0
  k8s-serviceaccount-crd:
    version: 2.0.1
  k8s-serviceaccount-operator:
    version: 1.0.0
backup:
  enabled: false
monitoring:
  enabled: false
use-lop-idp: true
defaultConfig:
  env:
    initialDomain: "k3ces.localdomain"
    initialFQDN: "k3ces.localdomain"