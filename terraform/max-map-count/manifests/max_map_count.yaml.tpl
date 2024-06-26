apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: max-map-count
  namespace: kube-system
  labels:
    app: max-map-count
spec:
  selector:
    matchLabels:
      app: max-map-count
  template:
    metadata:
      labels:
        app: max-map-count
    spec:
      nodeSelector:
%{ for s in node_selectors ~}
        ${s}
%{ endfor ~}
      hostNetwork: true
      hostPID: true
      hostIPC: true
      containers:
        - name: sysctl-set
          image: alpine:3.20.0
          imagePullPolicy: IfNotPresent
          command: ["/bin/sh", "-c"]
          args: [ "while true; do sysctl -w vm.max_map_count=262144; sleep 3600; done"]
          securityContext:
            privileged: true
      tolerations:
        - effect: "NoExecute"
          operator: "Exists"
        - effect: "NoSchedule"
          operator: "Exists"