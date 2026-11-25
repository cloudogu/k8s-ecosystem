# Installing a Global Proxy

- Install the Squid proxy with username/password authentication:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: squid-auth
  namespace: ecosystem
type: Opaque
stringData:
  username: proxyuser
  password: "S3cur3!Proxy:Pass#2026$"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: squid-config
  namespace: ecosystem
data:
  squid.conf: |
    auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
    auth_param basic realm cluster-proxy

    acl authenticated proxy_auth REQUIRED
    acl SSL_ports port 443
    acl Safe_ports port 80
    acl Safe_ports port 443
    acl CONNECT method CONNECT

    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports
    http_access allow authenticated
    http_access deny all

    http_port 3128
    visible_hostname squid-proxy

    access_log stdio:/var/log/squid/access.log
    cache deny all
    coredump_dir /var/spool/squid
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: squid-proxy
  namespace: ecosystem
spec:
  replicas: 1
  selector:
    matchLabels:
      app: squid-proxy
  template:
    metadata:
      labels:
        app: squid-proxy
    spec:
      initContainers:
        - name: generate-passwd
          image: httpd:2.4-alpine
          env:
            - name: PROXY_USERNAME
              valueFrom:
                secretKeyRef:
                  name: squid-auth
                  key: username
            - name: PROXY_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: squid-auth
                  key: password
          command:
            - /bin/sh
            - -ec
            - |
              htpasswd -cb /work/passwd "${PROXY_USERNAME}" "${PROXY_PASSWORD}"
          volumeMounts:
            - name: auth
              mountPath: /work
      containers:
        - name: squid
          image: ubuntu/squid:latest
          ports:
            - name: proxy
              containerPort: 3128
          volumeMounts:
            - name: config
              mountPath: /etc/squid/squid.conf
              subPath: squid.conf
            - name: auth
              mountPath: /etc/squid/passwd
              subPath: passwd
      volumes:
        - name: config
          configMap:
            name: squid-config
        - name: auth
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: squid-proxy
  namespace: ecosystem
spec:
  selector:
    app: squid-proxy
  ports:
    - name: proxy
      port: 3128
      targetPort: 3128
```


- Enable the proxy in the global configuration:

```bash
PATCH="$(
  kubectl -n ecosystem get configmap global-config -o json \
  | jq -c '{
      data: {
        "config.yaml": (
          .data["config.yaml"]
          + "\nproxy:\n"
          + "    enabled: \"true\"\n"
          + "    server: squid-proxy.ecosystem.svc.cluster.local\n"
          + "    port: \"3128\"\n"
          + "    username: proxyuser\n"
          + "    password: \"S3cur3!Proxy:Pass#2026$\"\n"
        )
      }
    }'
)"

kubectl -n ecosystem patch configmap global-config \
  --type=merge \
  -p "$PATCH"
```
Depending on the cluster being used, NetworkPolicies must be created to allow individual Dogus to access the Squid proxy.
