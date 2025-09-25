apiVersion: k8s.cloudogu.com/v2
kind: Blueprint
metadata:
  labels:
    app: ces
    app.kubernetes.io/name: k8s-blueprint-lib
  name: blueprint
spec:
  blueprint:
    dogus:
      - name: "official/cas"
        version: "7.2.6-3"
      - name: "official/ldap"
        version: "2.6.8-4"
      - name: "official/postfix"
        version: "3.10.2-2"
