apiVersion: k8s.cloudogu.com/v3
kind: Blueprint
metadata:
  labels:
    app: ces
    app.kubernetes.io/name: k8s-blueprint-lib
  name: blueprint
spec:
  displayName: "k3ces.localhost"
  stopped: false
  blueprint:
    dogus:
      - name: "official/cas"
        version: "7.2.6-3"
      - name: "official/ldap"
        version: "2.6.8-4"
      - name: "official/postfix"
        version: "3.10.2-2"
      - name: "official/usermgt"
        version: "1.20.0-5"
    config:
      dogus:
        ldap:
          - key: admin_password
            secretRef:
              key: admin-password
              name: initial-admin-password
            sensitive: true
      global:
        - key: "fqdn"
          value: "k3ces.localhost"
        - key: "domain"
          value: "k3ces.localhost"
        - key: "certificate/type"
          value: "selfsigned"
        - key: "password-policy/min_length"
          value: "1"
        - key: "password-policy/must_contain_capital_letter"
          value: "false"
        - key: "password-policy/must_contain_digit"
          value: "false"
        - key: "password-policy/must_contain_lower_case_letter"
          value: "false"
        - key: "password-policy/must_contain_special_character"
          value: "false"
  blueprintMask:
    manifest:
      dogus: []
